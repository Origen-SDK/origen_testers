module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestMethods
        class Limits
          attr_reader :test_method
          attr_reader :id
          attr_accessor :lo_limit, :hi_limit
          attr_accessor :unit
          attr_accessor :tnum
          attr_accessor :render
          alias_method :lo, :lo_limit
          alias_method :lo=, :lo_limit=
          alias_method :hi, :hi_limit
          alias_method :hi=, :hi_limit=

          def initialize(test_method, options = {})
            @test_method = test_method
            @tnum = ''
            @render = true
            @id = options[:id]

            unit = (options[:unit]) if options[:unit]
            set_lo_limit(options[:lo_limit]) if options[:lo_limit]
            set_hi_limit(options[:hi_limit]) if options[:hi_limit]
            @tnum = options[:tnum] if options[:tnum]
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

          def render?
            @render
          end

          private

          def test_name
            if test_method.limits_id.nil? && @id.nil?
              name = test_method.try(:test_name) || test_method.try(:_test_name) || test_method.try('TestName')
              name || 'Functional'
            elsif test_method.limits_id.nil?
              @id
            else
              test_method.limits_id
            end
          end
        end
      end
    end
  end
end
