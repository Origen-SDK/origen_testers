module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestMethods
        class Limits
          attr_reader :test_method
          attr_accessor :lo_limit, :hi_limit

          def initialize(test_method)
            @test_method = test_method
          end

          def to_s
            if !lo_limit && !hi_limit
              "\"#{test_name}\"" + ' = "":"NA":"":"NA":"":"":""'
            elsif !lo_limit
              "\"#{test_name}\"" + " = \"\":\"NA\":\"#{hi_limit}\":\"LE\":\"\":\"\":\"0\""
            elsif !hi_limit
              "\"#{test_name}\"" + " = \"#{lo_limit}\":\"GE\":\"\":\"NA\":\"\":\"\":\"0\""
            else
              "\"#{test_name}\"" + " = \"#{lo_limit}\":\"GE\":\"#{hi_limit}\":\"LE\":\"\":\"\":\"0\""
            end
          end

          def set_lo_limit(val)
            self.lo_limit = val
          end

          def set_hi_limit(val)
            self.hi_limit = val
          end

          private

          def test_name
            name = test_method.test_name if test_method.respond_to?(:test_name)
            name || 'Functional'
          end
        end
      end
    end
  end
end
