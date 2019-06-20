module OrigenTesters::ATP
  module Processors
    # Removes any conditions nodes that are nested within other condition
    # nodes that specify the same condition
    class RedundantConditionRemover < Processor
      def run(node)
        @conditions = []
        process(node)
      end

      def on_condition_node(node)
        sig = [node.type, node.to_a[0]]
        if @conditions.include?(sig)
          flag, *nodes = *node
          node.updated(:inline, process_all(nodes))
        else
          @conditions << sig
          node = node.updated(nil, process_all(node.children))
          @conditions.pop
          node
        end
      end
      OrigenTesters::ATP::Flow::CONDITION_NODE_TYPES.each do |type|
        alias_method "on_#{type}", :on_condition_node unless method_defined?("on_#{type}")
      end
    end
  end
end
