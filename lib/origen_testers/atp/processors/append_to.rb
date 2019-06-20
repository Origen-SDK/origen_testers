module OrigenTesters::ATP
  module Processors
    # Appends the given node to the node with the given ID, if it exists
    # somewhere within the given parent node
    class AppendTo < Processor
      def run(parent, node, id, options = {})
        @to_be_appended = node
        @id_of_to_be_appended_to = id
        @found = false
        process(parent)
      end

      def succeeded?
        @found
      end

      def handler_missing(node)
        if node.id == @id_of_to_be_appended_to
          @found = true
          node.updated(nil, node.children + [@to_be_appended])
        else
          node.updated(nil, process_all(node.children))
        end
      end
    end
  end
end
