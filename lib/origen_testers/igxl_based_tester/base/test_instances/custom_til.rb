module OrigenTesters
  module IGXLBasedTester
    class Base
      class TestInstances
        # Returns the test_instances object for the current flow
        attr_reader :test_instances

        # Custom Test Instance library
        class CustomTil
          def initialize(test_instances, definitions)
            @test_instances = test_instances
            @definitions = definitions
          end

          def method_missing(method, *args, &block)
            if definitions[method]
              m = platform::TestMethod.new methods: definitions[method].dup,
                                           attrs:   (args.first || {}),
                                           type:    method,
                                           library: self
              test_methods.add(m)
              m
            else
              super
            end
          end
        end
      end
    end
  end
end
