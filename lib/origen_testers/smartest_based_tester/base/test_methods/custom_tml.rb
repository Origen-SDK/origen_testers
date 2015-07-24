module Testers
  module SmartestBasedTester
    class Base
      class TestMethods
        class CustomTml < BaseTml
          def initialize(test_methods, definitions)
            @definitions = definitions
            @klass = definitions[:class_name]
            super test_methods
          end

          def klass
            @klass || ''
          end
        end
      end
    end
  end
end
