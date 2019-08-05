module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        class ExtractBinNames < ATP::Processor
          def run(node, options = {})
            @bin_names = { soft: {}, hard: {} }
            process(node)
            @bin_names
          end

          def on_bin_descriptions(node)
            node.children.each do |n|
              number, name = *n
              record number, name, type: n.type
            end
          end

          def on_test(node)
            if on_fail = node.find(:on_fail)
              if set_result = on_fail.find(:set_result)
                if bin = set_result.find(:bin)
                  if bin.to_a[1]
                    record(*bin.to_a, supplied: true, type: :hard)
                  else
                    record(*bin.to_a, default_name(node), type: :hard)
                  end
                end
                if sbin = set_result.find(:softbin)
                  if sbin.to_a[1]
                    record(*sbin.to_a, supplied: true, type: :soft)
                  else
                    record(*sbin.to_a, default_name(node), type: :soft)
                  end
                end
              end
            end
            process_all(node.children)
          end

          private

          def default_name(node)
            test_obj = node.find(:object).to_a[0]
            if test_obj.is_a?(Hash)
              suite_name = test_obj['Test']
            else
              suite_name = test_obj.respond_to?(:name) ? test_obj.name : test_obj
            end
            test_name = (node.find(:name) || []).to_a[0] || suite_name
            if suite_name == test_name
              suite_name
            else
              "#{suite_name}_#{test_name}"
            end
          end

          def record(number, name, options)
            table = @bin_names[options[:type]]
            if !table[number] || (options[:supplied] && !table[number][:supplied])
              table[number] = { name: name, supplied: options[:supplied] }
            end
          end
        end
      end
    end
  end
end
