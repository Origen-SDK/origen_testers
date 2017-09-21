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

          def on_on_fail(node)
            if to_inline = nodes_to_inline_on_pass_or_fail.last
              # If this node sets the flag that gates the node to be inlined
              set_run_flag = node.find(:set_run_flag)
              if set_run_flag && set_run_flag.to_a[0] == to_inline.to_a[0]
                # Remove the sub-node that sets the flag if there are no further references to it

                if @run_flag_table[set_run_flag.to_a[0]] == 1 || !@run_flag_table[set_run_flag.to_a[0]]
                  node = node.updated(nil, node.children - [set_run_flag])
                end

                # And append the content of the node to be in_lined at the end of this on pass/fail node
                append = to_inline.to_a[2..-1]

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
                  n.to_a[0] == node2.to_a[0] && # The flag set by node1 is gating node2
                  n.to_a[1] == 'auto_generated' && # The flag has been generated and not specified by the user
                  node2.to_a[1] == true && # Node2 is gated by the flag being in the set state
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

          def nodes_to_inline_on_pass_or_fail
            @nodes_to_inline_on_pass_or_fail ||= []
          end
        end
      end
    end
  end
end
