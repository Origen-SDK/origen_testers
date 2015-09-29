module OrigenTesters
  module IGXLBasedTester
    class Base
      class TestInstances
        # Custom Test Instance library
        class CustomTil
          # Returns the test_instances object for the current flow
          attr_reader :test_instances
          attr_reader :definitions

          def initialize(test_instances, definitions)
            @test_instances = test_instances
            @definitions = definitions
          end

          def method_missing(method, *args, &block)
            if definitions[method]
              name = args.shift
              ti = platform::CustomTestInstance.new name, methods: definitions[method].dup,
                                                          attrs:   (args.first || {}),
                                                          type:    method,
                                                          library: self
              test_instances.add(nil, ti)
              ti
            else
              super
            end
          end

          def platform
            test_instances.platform
          end
        end
      end
    end
  end
end
