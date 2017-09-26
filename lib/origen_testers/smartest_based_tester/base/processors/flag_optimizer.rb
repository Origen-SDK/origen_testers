module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        # This processor eliminates the use of run flags between adjacent tests:
        #
        #   s(:flow,
        #     s(:name, "prb1"),
        #     s(:test,
        #       s(:name, "test1"),
        #       s(:id, "t1"),
        #       s(:on_fail,
        #         s(:set_run_flag, "t1_FAILED", "auto_generated"),
        #         s(:continue))),
        #     s(:run_flag, "t1_FAILED", true,
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
        class FlagOptimizer < ATP::Processor
          attr_reader :run_flag_table

          def run(node)
            # Pre-process the AST for # of occurrences of each run-flag used
            t = ExtractRunFlagTable.new
            t.process(node)
            @run_flag_table = t.run_flag_table
            process(node)
          end

          def on_named_collection(node)
            name, *nodes = *node
            node.updated(nil, [name] + optimize(process_all(nodes)))
          end
          alias_method :on_flow, :on_named_collection
          alias_method :on_group, :on_named_collection

          def on_run_flag(node)
            name, state, *nodes = *node
            if run_flag_to_remove.last && run_flag_to_remove.last == node.to_a[0..1]
              node.to_a.last
            else
              node.updated(nil, [name, state] + optimize(process_all(nodes)))
            end
          end

          def on_on_fail(node)
            if to_inline = nodes_to_inline_on_pass_or_fail.last
              # If this node sets the flag that gates the node to be inlined
              set_run_flag = node.find(:set_run_flag)
              if set_run_flag && gated_by_set?(set_run_flag.to_a[0], to_inline)
                # Remove the sub-node that sets the flag if there are no further references to it

                if @run_flag_table[set_run_flag.to_a[0]] == 1 || !@run_flag_table[set_run_flag.to_a[0]]
                  node = node.updated(nil, node.children - [set_run_flag])
                end

                # And append the content of the node to be in_lined at the end of this on pass/fail node
                append = reorder_nested_run_flags(set_run_flag.to_a[0], to_inline).to_a[2..-1]

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
            if node1.type == :test && node2.type == :run_flag
              if node1.find_all(:on_fail, :on_pass).any? do |node|
                if n = node.find(:set_run_flag)
                  # Inline instead of setting a flag if...
                  gated_by_set?(n.to_a[0], node2) && # The flag set by node1 is gating node2
                  n.to_a[1] == 'auto_generated' && # The flag has been generated and not specified by the user
                  n.to_a[0] !~ /_RAN$/ # And don't compress RAN flags because they can be set by both on_fail and on_pass
                end
              end
                return true
              end
            end
            false
          end

          def combine(node1, node2)
            nodes_to_inline_on_pass_or_fail << node2
            node1 = node1.updated(nil, process_all(node1.children))
            nodes_to_inline_on_pass_or_fail.pop
            node1
          end

          # node will always be a run_flag type node, guaranteed by the caller
          #
          # Returns true if flag matches the one supplied and it is required to be set(true), like this:
          #
          #   s(:run_flag, flag, true,
          #     s(:test, ...
          #
          # Also returns true if flag matches the one supplied, but it is nested within other flag conditions:
          #
          #   s(:run_flag, other_flag, false,
          #     s(:run_flag, other_flag2, true,
          #       s(:run_flag, flag, true,
          #         s(:test, ...
          def gated_by_set?(flag, node)
            (flag == node.to_a[0] && node.to_a[1]) ||
              (node.to_a.size == 3 && node.to_a.last.type == :run_flag && gated_by_set?(flag, node.to_a.last))
          end

          # Returns the node with the run_flag clauses re-ordered to have the given flag of interest at the top.
          #
          # The caller guarantees the run_flag clause containing the given flag is present.
          #
          # For example, given this node:
          #
          #   s(:run_flag, "flag1", false,
          #     s(:run_flag, "ot_BEA7F3B_FAILED", true,
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
          #   s(:run_flag, "ot_BEA7F3B_FAILED", true,
          #     s(:run_flag, "flag1", false,
          #       s(:test,
          #         s(:object, <TestSuite: inner_test1_BEA7F3B>),
          #         s(:name, "inner_test1_BEA7F3B"),
          #         s(:number, 0),
          #         s(:id, "it1_BEA7F3B"),
          #         s(:on_fail,
          #           s(:render, "multi_bin;")))))
          def reorder_nested_run_flags(flag, node)
            # If the run_flag we care about is already at the top, just return node
            unless node.to_a[0] == flag && node.to_a[1]
              run_flag_to_remove << [flag, true]
              node = n(:run_flag, [flag, true, process(node)])
              run_flag_to_remove.pop
            end
            node
          end

          def run_flag_to_remove
            @run_flag_to_remove ||= []
          end

          def nodes_to_inline_on_pass_or_fail
            @nodes_to_inline_on_pass_or_fail ||= []
          end
        end
      end
    end
  end
end
