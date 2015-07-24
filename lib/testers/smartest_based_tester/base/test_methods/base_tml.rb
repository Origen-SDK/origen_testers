module Testers
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
            RGen.interface.platform
          end

          def definitions
            @definitions || self.class::TEST_METHODS
          end
        end
      end
    end
  end
end
