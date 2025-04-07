module OrigenTesters::ATP
  module Processors
    # This processor eliminates the use of run flags between adjacent tests:
    #
    #   s(:flow,
    #     s(:name, "prb1"),
    #     s(:test,
    #       s(:name, "test1"),
    #       s(:id, "t1"),
    #       s(:on_fail,
    #         s(:set_flag, "t1_FAILED", "auto_generated"),
    #         s(:continue))),
    #     s(:if_flag, "t1_FAILED",
    #       s(:test,
    #         s(:name, "test2"))))
    #
    #
    #   s(:flow,
    #     s(:name, "prb1"),
    #     s(:test,
    #       s(:name, "test1"),
    #       s(:id, "t1"),
    #       s(:on_fail,
    #         s(:test,
    #           s(:name, "test2")))))
    #
    class FlagOptimizer < Processor
      attr_reader :run_flag_table, :optimize_when_continue

      class ExtractRunFlagTable < Processor
        # Hash table of run_flag name with number of times used
        attr_reader :run_flag_table

        # Reset hash table
        def initialize
          @run_flag_table = {}.with_indifferent_access
        end

        # For run_flag nodes, increment # of occurrences for specified flag
        def on_if_flag(node)
          children = node.children.dup
          names = children.shift
          state = node.type == :if_flag
          Array(names).each do |name|
            if @run_flag_table[name.to_sym].nil?
              @run_flag_table[name.to_sym] = 1
            else
              @run_flag_table[name.to_sym] += 1
            end
          end
          process_all(node.children)
        end
        alias_method :on_unless_flag, :on_if_flag
      end

      def run(node, options = {})
        options = {
          optimize_when_continue: true
        }.merge(options)
        @optimize_when_continue = options[:optimize_when_continue]
        # Pre-process the AST for # of occurrences of each run-flag used
        t = ExtractRunFlagTable.new
        t.process(node)
        @run_flag_table = t.run_flag_table
        extract_volatiles(node)
        process(node)
      end

      def on_named_collection(node)
        name, *nodes = *node
        node.updated(nil, [name] + optimize(process_all(nodes)))
      end
      alias_method :on_flow, :on_named_collection
      alias_method :on_group, :on_named_collection
      alias_method :on_unless_flag, :on_named_collection
      alias_method :on_sub_flow, :on_named_collection

      def on_unnamed_collection(node)
        node.updated(nil, optimize(process_all(node.children)))
      end
      alias_method :on_else, :on_unnamed_collection

      def on_whenever(node)
        name, *nodes = *node
        node.updated(nil, [name] + optimize(process_all(nodes)))
      end
      alias_method :on_whenever_all, :on_whenever
      alias_method :on_whenever_any, :on_whenever

      def on_if_flag(node)
        name, *nodes = *node
        # Remove this node and return its children if required
        if if_run_flag_to_remove.last == node.to_a[0]
          node.updated(:inline, optimize(process_all(node.to_a[1..-1])))
        else
          node.updated(nil, [name] + optimize(process_all(nodes)))
        end
      end

      def on_on_fail(node)
        if to_inline = nodes_to_inline_on_pass_or_fail.last
          # If this node sets the flag that gates the node to be inlined
          set_flag = node.find(:set_flag)
          if set_flag && gated_by_set?(set_flag.to_a[0], to_inline)
            # Remove the sub-node that sets the flag if there are no further references to it

            if @run_flag_table[set_flag.to_a[0]] == 1 || !@run_flag_table[set_flag.to_a[0]]
              node = node.updated(nil, node.children - [set_flag])
            end

            # And append the content of the node to be in_lined at the end of this on pass/fail node
            append = reorder_nested_run_flags(set_flag.to_a[0], to_inline).to_a[1..-1]

            # Belt and braces approach to make sure this node to be inlined does
            # not get picked up anywhere else
            nodes_to_inline_on_pass_or_fail.pop
            nodes_to_inline_on_pass_or_fail << nil
          end
        end
        node.updated(nil, optimize(process_all(node.children + Array(append))))
      end
      alias_method :on_on_pass, :on_on_fail

      def optimize(nodes)
        results = []
        node1 = nil
        nodes.each do |node2|
          binding.pry if node2.find(:id)&.value == "pptest_rmhi_pmin01_7877627" 
          binding.pry if node2.find_all(:on_fail, :on_pass).any? { |dn| dn.find(:set_flag).to_a[0] == "pptest_rmhi_pmin01_7877627_FAILED" }
          if node1
            if can_be_combined?(node1, node2)
              node1 = combine(node1, node2)
            else
              results << node1
              node1 = node2
            end
          else
            node1 = node2
          end
        end
        results << node1 if node1
        results
      end

      def can_be_combined?(node1, node2)
        if (node1.type == :test || node1.type == :sub_flow) && (node2.type == :if_flag || node2.type == :unless_flag) &&
           # Don't optimize tests which are marked as continue if told not to
           !(node1.find(:on_fail) && node1.find(:on_fail).find(:continue) && !optimize_when_continue)

        # if if_run_flag_to_remove.last == node.to_a[0] || node.to_a[0] == "pptest_rmhi_pmin01_7877627_PASSED"
          if node1.find_all(:on_fail, :on_pass).any? do |node|
            if n = node.find(:set_flag)
              # Inline instead of setting a flag if...
              gated_by_set?(n.to_a[0], node2) && # The flag set by node1 is gating node2
              n.to_a[1] == 'auto_generated' && # The flag has been generated and not specified by the user
              n.to_a[0] !~ /_RAN$/ && # And don't compress RAN flags because they can be set by both on_fail and on_pass
              !volatile?(n.to_a[0]) # And make sure the flag has not been marked as volatile
            end
          end
            return true
          end
        end
        false
      end

      def combine(node1, node2)
        nodes_to_inline_on_pass_or_fail << node2 # .updated(nil, process_all(node2.children))
        node1 = node1.updated(nil, process_all(node1.children))
        nodes_to_inline_on_pass_or_fail.pop
        node1
      end

      # node will always be an if_flag or unless_flag type node, guaranteed by the caller
      #
      # Returns true if flag matches the one supplied
      #
      #   s(:if_flag, flag,
      #     s(:test, ...
      #
      # Also returns true if flag matches the one supplied, but it is nested within other flag conditions:
      #
      #   s(:unless_flag, other_flag,
      #     s(:if_flag, other_flag2,
      #       s(:if_flag, flag,
      #         s(:test, ...
      def gated_by_set?(flag, node)
        (flag == node.to_a[0] && node.type == :if_flag) ||
          (node.to_a.size == 2 && (node.to_a.last.type == :if_flag || node.to_a.last.type == :unless_flag) && gated_by_set?(flag, node.to_a.last))
      end

      # Returns the node with the run_flag clauses re-ordered to have the given flag of interest at the top.
      #
      # The caller guarantees the run_flag clause containing the given flag is present.
      #
      # For example, given this node:
      #
      #   s(:unless_flag, "flag1",
      #     s(:if_flag, "ot_BEA7F3B_FAILED",
      #       s(:test,
      #         s(:object, <TestSuite: inner_test1_BEA7F3B>),
      #         s(:name, "inner_test1_BEA7F3B"),
      #         s(:number, 0),
      #         s(:id, "it1_BEA7F3B"),
      #         s(:on_fail,
      #           s(:render, "multi_bin;")))))
      #
      # Then this node would be returned when the flag of interest is ot_BEA7F3B_FAILED:
      #
      #   s(:if_flag, "ot_BEA7F3B_FAILED",
      #     s(:unless_flag, "flag1",
      #       s(:test,
      #         s(:object, <TestSuite: inner_test1_BEA7F3B>),
      #         s(:name, "inner_test1_BEA7F3B"),
      #         s(:number, 0),
      #         s(:id, "it1_BEA7F3B"),
      #         s(:on_fail,
      #           s(:render, "multi_bin;")))))
      def reorder_nested_run_flags(flag, node)
        # If the run_flag we care about is already at the top, just return node
        unless node.to_a[0] == flag && node.type == :if_flag
          if_run_flag_to_remove << flag
          node = node.updated(:if_flag, [flag] + [process(node)])
          if_run_flag_to_remove.pop
        end
        node
      end

      def if_run_flag_to_remove
        @if_run_flag_to_remove ||= []
      end

      def nodes_to_inline_on_pass_or_fail
        @nodes_to_inline_on_pass_or_fail ||= []
      end
    end
  end
end
