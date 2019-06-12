module OrigenTesters::ATP
  module Processors
    # Removes all :sub_flow nodes
    class SubFlowRemover < Processor
      def on_sub_flow(node)
        node.updated(:remove, nil)
      end
    end
  end
end
