module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestMethods
        # Base class of all test method libraries
        class BaseTml
          # Returns the test_methods object for the current flow
          attr_reader :test_methods

          def initialize(test_methods)
            @test_methods = test_methods
          end

          def method_missing(method, *args, &block)
            if definitions[method]
              instantiate_test_method(method, args)
            else
              method = method.to_s.underscore.to_sym
              if definitions[method]
                instantiate_test_method(method, args)
              else
                super
              end
            end
          end

          def platform
            Origen.interface.platform
          end

          def definitions
            @definitions || self.class::TEST_METHODS
          end

          private

          def instantiate_test_method(method, args)
            m = platform::TestMethod.new methods: definitions[method].dup,
                                         attrs:   (args.first || {}),
                                         type:    method,
                                         library: self
            test_methods.add(m)
            m
          end
        end
      end
    end
  end
end
