require 'set'
module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        # Returns an array containing all flow control variables from the given AST node
        # and their default value
        class ExtractFlowControlVars < ATP::Processor
          def run(node, options = {})
            @variables = Set.new
            process(node)
            @variables.to_a.sort do |x, y|
              x = x[0] if x.is_a?(Array)
              y = y[0] if y.is_a?(Array)
              x <=> y
            end
          end

          def on_if_job(node)
            if tester.smt8?
              @variables << ['JOB', '']
            end
            process_all(node.children)
          end
          alias_method :on_unless_job, :on_if_job

          def on_if_enabled(node)
            flag, *nodes = *node
            [flag].flatten.each do |f|
              @variables << generate_flag_name(f)
            end
            process_all(nodes)
          end
          alias_method :on_unless_enabled, :on_if_enabled

          def on_enable(node)
            flag = node.value.upcase
            @variables << flag
          end
          alias_method :on_disable, :on_enable

          private

          def generate_flag_name(flag)
            SmartestBasedTester::Base::Flow.generate_flag_name(flag)
          end
        end
      end
    end
  end
end
