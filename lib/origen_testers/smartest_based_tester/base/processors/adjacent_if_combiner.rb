module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        class AdjacentIfCombiner < ATP::Processor
          class SetRunFlagFinder < ATP::Processor
            def contains?(node, flag_name)
              @result = false
              @flag_name = flag_name
              process_all(node)
              @result
            end

            def on_set_run_flag(node)
              if node.to_a[0] == @flag_name
                @result = true
              end
            end
          end

          def on_named_collection(node)
            name, *nodes = *node
            node.updated(nil, [name] + optimize(process_all(nodes)))
          end
          alias_method :on_flow, :on_named_collection
          alias_method :on_group, :on_named_collection

          def on_group(node)
            name, *nodes = *node
            node.updated(nil, [name] + optimize(process_all(nodes)))
          end

          def optimize(nodes)
            results = []
            node1 = nil
            nodes.each do |node2|
              if node1
                if opposite_flag_states?(node1, node2) && safe_to_combine?(node1, node2)
                  results << combine(node1, node2)
                  node1 = nil
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

          def combine(node1, node2)
            true_node = node1.to_a[0] ? node1 : node2
            false_node = node1.to_a[0] ? node2 : node1
            true_node = n(:flag_true, process_all(true_node.to_a[2..-1]))
            false_node = n(:flag_false, process_all(false_node.to_a[2..-1]))

            n(node1.type, [node1.to_a[0], true_node, false_node])
          end

          def opposite_flag_states?(node1, node2)
            node1.type == :run_flag && node2.type == :run_flag &&
              node1.to_a[0] == node2.to_a[0] && node1.to_a[1] != node2.to_a[1]
          end

          def safe_to_combine?(node1, node2)
            !SetRunFlagFinder.new.contains?(node1, node1.to_a[0]) &&
              !SetRunFlagFinder.new.contains?(node2, node2.to_a[0])
          end
        end
      end
    end
  end
end
