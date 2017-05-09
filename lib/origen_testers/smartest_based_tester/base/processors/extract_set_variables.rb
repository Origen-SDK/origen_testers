module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        # Extracts all runtime variables which are set within the given flow, returning
        # them in an array
        class ExtractSetVariables < ATP::Processor
          def run(nodes)
            @results = []
            process_all(nodes)
            @results.uniq
          end

          def on_set_run_flag(node)
            flag = node.value.upcase
            @results << flag
          end
        end
      end
    end
  end
end
