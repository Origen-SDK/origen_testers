module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        class FlagOptimizer < ATP::Processor
          # This optimizes the AST such that any adjacent flow noes that
          #
          # For example this AST:
          #   (flow
          #     (test
          #       (name "test1")
          #       (on-fail
          #         (set-run-flag "t1_FAILED")))
          #     (run-flag "t1_FAILED" true
          #       (test
          #         (name "test2"))
          #       (test
          #         (name "test3")))
          #     (test
          #       (name "test4")
          #       (on-pass
          #         (set-run-flag "t4_PASSED"))
          #       (on-fail
          #         (continue)))
          #     (run-flag "t4_PASSED" true
          #       (test
          #         (name "test5"))
          #       (test
          #         (name "test6"))))
          #
          # Will be optimized to this:
          #   (flow
          #     (test
          #       (name "test1")
          #       (on-fail
          #         (test
          #           (name "test2"))
          #         (test
          #           (name "test3"))))
          #     (test
          #       (name "test4")
          #       (on-pass
          #         (test
          #           (name "test5"))
          #         (test
          #           (name "test6")))
          #       (on-fail
          #         (continue))))

          # Only run this on top level flow and consider adjacent nodes, no need for
          # looking at nested conditions.
          def on_flow(node)
            name, *nodes = *node
            results = []
            node_a = nil
            nodes.each do |node_b|
              if node_a && node_a.type == :test && node_b.type == :run_flag
                result, node_a = remove_run_flag(node_a, node_b)
                results << result
              else
                results << node_a unless node_a.nil?
                node_a = node_b
              end
            end
            results << node_a unless node_a.nil?
            node.updated(nil, [name] + results)
          end

          # Given two adjacent nodes, where the first (a) is a test and the second (b)
          # is a run_flag, determine if (a) conditionally sets the same flag that (b)
          # uses.  If it does, do a logical replacement, if not, move on quietly.
          def remove_run_flag(node_a, node_b)
            on_pass = node_a.find(:on_pass)
            on_fail = node_a.find(:on_fail)

            unless on_pass.nil? && on_fail.nil?
              if on_pass.nil?
                flag_node = on_fail.find(:set_run_flag)
                conditional = [flag_node, on_fail]
              else
                flag_node = on_pass.find(:set_run_flag)
                conditional = [flag_node, on_pass]
              end
            end
            unless conditional.nil?
              children = node_b.children.dup
              name = children.shift
              state = children.shift
              *nodes = *children
              flag_node_b = n1(:set_run_flag, name) if state == true

              if conditional.first == flag_node_b
                o = conditional.last.dup
                result = node_a.remove(o)
                n = o.remove(conditional.first)
                n = n.updated(nil, n.children + (nodes.is_a?(Array) ? nodes : [nodes]))
                result = result.updated(nil, result.children + (n.is_a?(Array) ? n : [n]))
                return result, nil
              end
            end
            [node_a, node_b]
          end
        end
      end
    end
  end
end
