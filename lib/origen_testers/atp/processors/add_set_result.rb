module OrigenTesters::ATP
  module Processors
    # Makes sure every test node has an on_fail/set_result node,
    class AddSetResult < Processor
      def run(node)
        process(node)
      end

      def on_test(node)
        node = node.ensure_node_present(:on_fail)
        node.updated(nil, process_all(node))
      end

      def on_on_fail(node)
        unless node.find(:continue)
          node = node.ensure_node_present(:set_result, 'fail')
        end
        node.updated(nil, process_all(node))
      end
    end
  end
end
