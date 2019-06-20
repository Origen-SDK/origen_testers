module OrigenTesters::ATP
  module Validators
    class DuplicateIDs < Validator
      def on_completion
        if @duplicate_ids
          @duplicate_ids.each do |id, nodes|
            error "Test ID #{id} is defined more than once in flow #{flow.name}:"
            nodes.each do |node|
              error "  #{node.source}"
            end
          end
          true
        end
      end

      def on_id(node)
        @existing_ids ||= {}
        id = node.value
        if @existing_ids[id]
          @duplicate_ids ||= {}
          if @duplicate_ids[id]
            @duplicate_ids[id] << node
          else
            @duplicate_ids[id] = [@existing_ids[id], node]
          end
        else
          @existing_ids[id] = node
        end
      end
    end
  end
end
