module OrigenTesters::ATP
  module Processors
    # Removes most things from embedded on_pass/fail nodes and converts them to the equivalent
    # on_passed/failed condition at the same level as the parent node
    class OnPassFailRemover < Processor
      def run(node)
        process(node)
      end

      def on_test(node)
        on_pass = node.find(:on_pass)
        on_fail = node.find(:on_fail)
        if on_pass || on_fail
          id = node.find(:id)
          unless id
            fail 'Something has gone wrong, all nodes should have IDs by this point'
          end

          id = id.value
          nodes = [node]
          if on_fail && contains_anything_interesting?(on_fail)
            nodes << node.updated(:if_failed, [id] + on_fail.children)
            nodes[0] = nodes[0].remove(on_fail)
          end
          if on_pass && contains_anything_interesting?(on_pass)
            nodes << node.updated(:if_passed, [id] + on_pass.children)
            nodes[0] = nodes[0].remove(on_pass)
          end
          node.updated(:inline, nodes)
        else
          node.updated(nil, process_all(node.children))
        end
      end

      def contains_anything_interesting?(node)
        node.children.any? { |n| n.type != :set_result && n.type != :continue && n.type != :set_flag }
      end
    end
  end
end
