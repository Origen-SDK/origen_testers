module OrigenTesters::ATP
  module Processors
    # Assigns an ID to all test nodes that don't have one
    class AddIDs < Processor
      def run(node)
        @i = 0
        @existing_ids = []
        @add_ids = false
        # First collect all existing IDs, this is required to make sure
        # that a generated ID does not clash with an existing one
        process(node)
        # Now run again to fill in the blanks
        @add_ids = true
        process(node)
      end

      def on_test(node)
        if @add_ids
          node = node.ensure_node_present(:id)
          node.updated(nil, process_all(node))
        else
          if id = node.find(:id)
            @existing_ids << id.value
          end
          process_all(node)
        end
      end
      alias_method :on_group, :on_test

      def on_id(node)
        if @add_ids
          unless node.value
            node.updated(nil, [next_id])
          end
        end
      end

      def next_id
        @i += 1
        @i += 1 while @existing_ids.include?("t#{@i}")
        "t#{@i}"
      end
    end
  end
end
