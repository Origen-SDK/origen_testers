module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        class IfRanCleaner < ATP::Processor
          def on_test(node)
            on_pass = node.find(:on_pass)
            on_fail = node.find(:on_fail)

            unless on_pass.nil? || on_fail.nil?
              set_run_flag = on_fail.find(:set_run_flag)
              set_result = on_fail.find(:set_result)
              unless set_run_flag.nil? || set_result.nil?
                children = set_run_flag.children.dup
                name = children.shift
                ag_string = children.shift

                if name =~ /_RAN$/ && ag_string == 'auto_generated'
                  f = on_fail.dup
                  f = f.remove(set_result)
                  n = node.remove(on_fail)
                  n = n.updated(nil, n.children + (f.is_a?(Array) ? f : [f]))
                  return n
                end

              end
            end
            node
          end
        end
      end
    end
  end
end
