module OrigenTesters::ATP
  module Processors
    # Implements continue on a fail branch for V93K by removing any bin nodes that are
    # siblings of continue nodes. The continue nodes are also removed in the process since
    # they have now served their function.
    class ContinueImplementer < OrigenTesters::ATP::Processor
      # Delete any on-fail child if it's 'empty'
      def on_on_fail(node)
        if cont = node.find(:continue) || @continue
          node = node.updated(nil, node.children - [cont] - node.find_all(:set_result))
        end
        node.updated(nil, process_all(node.children))
      end

      def on_group(node)
        f = node.find(:on_fail)
        if f && f.find(:continue)
          with_continue do
            node = node.updated(nil, process_all(node.children))
          end
          node
        else
          node.updated(nil, process_all(node.children))
        end
      end

      def with_continue
        orig = @continue
        @continue = true
        yield
        @continue = orig
      end
    end
  end
end
