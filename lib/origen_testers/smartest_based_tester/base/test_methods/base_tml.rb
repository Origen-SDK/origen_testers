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
            tml_class_name = self.class.name.to_s.split('::')[-1]
            # This enables passing camel case test methods for dc_tml and ac_tml
            unless tml_class_name == 'CustomTml'
              method = method.to_s.underscore.to_sym if camelcase?(method)
            end
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

          def platform
            Origen.interface.platform
          end

          def definitions
            @definitions || self.class::TEST_METHODS
          end

          private

          def camelcase?(test_method)
            test_method.to_s.camelcase.to_sym == test_method ? true : false
          end
        end
      end
    end
  end
end
