module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestMethods
        # Base class of all test method libraries
        class BaseTml
          def self.test_method_classes
            @test_method_classes ||= {}
          end

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
            definition = definitions[method]
            base_class = platform::TestMethod
            cache_key = [base_class, definition.object_id]
            klass = BaseTml.test_method_classes[cache_key] ||= begin
              generated_class = Class.new(base_class)
              # Retain the definition so its object ID cannot be recycled while
              # this generated class remains cached.
              generated_class.instance_variable_set(:@test_method_definition, definition)
              generated_class
            end
            m = klass.new methods: definition.dup,
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
