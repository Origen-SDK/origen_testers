module OrigenTesters::ATP
  module Processors
    # Gives every node their own individual wrapping of condition nodes. No attempt is made
    # to identify or remove duplicate conditions in the wrapping, that will be done later by
    # the RedundantConditionRemover.
    class Flattener < Processor
      def run(node)
        @results = [[]]
        @conditions = []
        process(node)
        node.updated(:flow, results)
      end

      def on_flow(node)
        process_all(node.children)
      end

      # Handles the top-level flow nodes
      def on_volatile(node)
        results << node
      end
      alias_method :on_name, :on_volatile
      alias_method :on_id, :on_volatile

      def on_group(node)
        @results << []
        process_all(node.children)
        nodes = @results.pop
        results << node.updated(nil, nodes)
      end

      def on_condition_node(node)
        flag, *nodes = *node
        @conditions << node.updated(node.type, [flag])
        process_all(nodes)
        @conditions.pop
      end
      OrigenTesters::ATP::Flow::CONDITION_NODE_TYPES.each do |type|
        alias_method "on_#{type}", :on_condition_node unless method_defined?("on_#{type}")
      end

      def handler_missing(node)
        results << wrap_with_current_conditions(node)
      end

      def wrap_with_current_conditions(node)
        @conditions.reverse_each do |condition|
          node = condition.updated(nil, condition.children + [node])
        end
        node
      end

      def results
        @results.last
      end
    end
  end
end
