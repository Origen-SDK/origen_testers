module OrigenTesters::ATP
  module Processors
    # Modifies the AST by performing some basic clean up, mainly to sanitize
    # user input. For example it will ensure that all IDs and references are underscored
    # and lower cased.
    class PreCleaner < Processor
      def initialize
        @group_ids = []
      end

      # Make all IDs lower cased symbols
      # unless literal_flags is set
      def on_id(node)
        id = node.to_a[0]
        if tester.literal_flags
          node.updated(nil, [id])
        else
          node.updated(nil, [clean(id)])
        end
      end

      # Make all ID references use the lower case symbols
      # unless literal_flags is set
      def on_if_failed(node)
        id, *children = *node
        if tester.literal_flags
          node.updated(nil, [id] + process_all(children))
        else
          node.updated(nil, [clean(id)] + process_all(children))
        end
      end
      alias_method :on_if_passed, :on_if_failed
      alias_method :on_if_any_failed, :on_if_failed
      alias_method :on_if_all_failed, :on_if_failed
      alias_method :on_if_any_passed, :on_if_failed
      alias_method :on_if_all_passed, :on_if_failed
      alias_method :on_if_ran, :on_if_failed
      alias_method :on_unless_ran, :on_if_failed
      alias_method :on_if_any_sites_failed, :on_if_failed
      alias_method :on_if_all_sites_failed, :on_if_failed
      alias_method :on_if_any_sites_passed, :on_if_failed
      alias_method :on_if_all_sites_passed, :on_if_failed

      def on_group(node)
        if id = node.children.find { |n| n.type == :id }
          @group_ids << process(id).value
        else
          @group_ids << nil
        end
        group = node.updated(nil, process_all(node.children))
        @group_ids.pop
        group
      end
      alias_method :on_sub_flow, :on_group

      def on_test(node)
        # Remove IDs nodes from test nodes if they refer to the ID of a parent group
        if @group_ids.last
          children = node.children.reject do |n|
            if n.type == :id
              @group_ids.last == process(n).value
            end
          end
        else
          children = node.children
        end
        node.updated(nil, process_all(children))
      end

      def clean(id)
        if id.is_a?(Array)
          id.map { |i| clean(i) }
        else
          id.to_s.symbolize.to_s
        end
      end
    end
  end
end
