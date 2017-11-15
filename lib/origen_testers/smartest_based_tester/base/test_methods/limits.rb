module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestMethods
        class Limits
          attr_reader :test_method
          attr_accessor :lo_limit, :hi_limit
          attr_accessor :unit
          attr_accessor :tnum
          alias_method :lo, :lo_limit
          alias_method :lo=, :lo_limit=
          alias_method :hi, :hi_limit
          alias_method :hi=, :hi_limit=

          def initialize(test_method)
            @test_method = test_method
            @tnum = ''
          end

          def unit=(val)
            case val.to_s.downcase
            when 'v', 'volts'
              @unit = 'V'
            when 'a', 'amps'
              @unit = 'A'
            else
              fail "Limit unit of #{val} not implemented yet!"
            end
          end

          def to_s
            if !lo_limit && !hi_limit
              if tnum == ''
                "\"#{test_name}\"" + ' = "":"NA":"":"NA":"":"":""'
              else
                "\"#{test_name}\"" + " = \"\":\"NA\":\"\":\"NA\":\"\":\"#{tnum}\":\"0\""
              end
            elsif !lo_limit
              "\"#{test_name}\"" + " = \"\":\"NA\":\"#{hi_limit}\":\"LE\":\"#{unit}\":\"#{tnum}\":\"0\""
            elsif !hi_limit
              "\"#{test_name}\"" + " = \"#{lo_limit}\":\"GE\":\"\":\"NA\":\"#{unit}\":\"#{tnum}\":\"0\""
            else
              "\"#{test_name}\"" + " = \"#{lo_limit}\":\"GE\":\"#{hi_limit}\":\"LE\":\"#{unit}\":\"#{tnum}\":\"0\""
            end
          end

          def set_lo_limit(val)
            self.lo_limit = val
          end

          def set_hi_limit(val)
            self.hi_limit = val
          end

          def to_atp_attributes
            r = []
            if lo_limit
              r << { value: lo_limit, rule: 'LE', units: unit }
            end
            if hi_limit
              r << { value: hi_limit, rule: 'GE', units: unit }
            end
            r
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
