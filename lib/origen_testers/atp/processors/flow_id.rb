module OrigenTesters::ATP
  module Processors
    # Adds the flow ID to all ids and label names
    class FlowID < Processor
      attr_reader :id

      def run(node, id)
        @id = id
        process(node)
      end

      def on_id(node)
        if node.value =~ /^extern/ || node.value =~ /_extern/
          node
        else
          node.updated(nil, ["#{node.value}_#{id}"])
        end
      end

      def on_if_failed(node)
        tid, *nodes = *node
        if tid.is_a?(Array)
          tid = tid.map do |tid|
            if tid =~ /^extern/ || node.value =~ /_extern/
              tid
            else
              tid = "#{tid}_#{id}"
            end
          end
        else
          if tid =~ /^extern/ || node.value =~ /_extern/
            tid
          else
            tid = "#{tid}_#{id}"
          end
        end
        node.updated(nil, [tid] + process_all(nodes))
      end
      alias_method :on_if_any_failed, :on_if_failed
      alias_method :on_if_all_failed, :on_if_failed
      alias_method :on_if_passed, :on_if_failed
      alias_method :on_if_any_passed, :on_if_failed
      alias_method :on_if_all_passed, :on_if_failed
      alias_method :on_if_ran, :on_if_failed
      alias_method :on_unless_ran, :on_if_failed
      alias_method :on_if_any_sites_failed, :on_if_failed
      alias_method :on_if_all_sites_failed, :on_if_failed
      alias_method :on_if_any_sites_passed, :on_if_failed
      alias_method :on_if_all_sites_passed, :on_if_failed
    end
  end
end
