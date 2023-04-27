module OrigenTesters
  module IGXLBasedTester
    class Base
      class FlowLine
        attr_accessor :type, :cz_setup # cz_setup is a virtual attrib since it is not part of the regular flow line
        attr_writer :id

        # cz_setup combine with instance name when characterize opcode is used

        # Map any aliases to the official names here, multiple aliases for a given attribute
        # are allowed
        ALIASES = {
          bin:            :bin_fail,
          softbin:        :sort_fail,
          soft_bin:       :sort_fail,
          sbin:           :sort_fail,
          name:           :tname,
          number:         :tnum,
          if_enable:      :enable,
          if_enabled:     :enable,
          enabled:        :enable,
          hi_limit:       :hilim,
          hi:             :hilim,
          lo_limit:       :lolim,
          lo:             :lolim,
          # Aliases can also be used to set defaults on multiple attributes like this,
          # use :value to refer to the value passed in to the given alias
          flag_false:     { device_condition: 'flag-false',
                            device_name:      :value },
          flag_true:      { device_condition: 'flag-true',
                            device_name:      :value },
          flag_false_any: { group_specifier: 'any-active',
                            group_condition: 'flag-false',
                            group_name:      :value },
          flag_false_all: { group_specifier: 'all-active',
                            group_condition: 'flag-false',
                            group_name:      :value },
          flag_true_any:  { group_specifier: 'any-active',
                            group_condition: 'flag-true',
                            group_name:      :value },
          flag_true_all:  { group_specifier: 'all-active',
                            group_condition: 'flag-true',
                            group_name:      :value },
          flag_clear:     { device_condition: 'flag-clear',
                            device_name:      :value }
        }

        # Assign attribute defaults here, generally this should match whatever defaults
        # Teradyne has set whenever you create a new test instance, etc.
        DEFAULTS = {
          test:              {
            opcode: 'Test',
            result: 'Fail'
          },
          test_defer_limits: {
            opcode: 'Test-defer-limits',
            result: 'Fail'
          },
          cz:                {
            opcode: 'characterize',
            result: 'None'
          },
          goto:              {
            opcode: 'goto'
          },
          nop:               {
            opcode: 'nop'
          },
          set_device:        {
            opcode: 'set-device'
          },
          set_error_bin:     {
            opcode: 'set-error-bin'
          },
          enable_flow_word:  {
            opcode: 'enable-flow-word'
          },
          disable_flow_word: {
            opcode: 'disable-flow-word'
          },
          logprint:          {
            opcode: 'logprint'
          },
          use_limit:         {
            opcode: 'Use-Limit',
            result: 'Fail'
          },
          flag_false:        {
            opcode: 'flag-false'
          },
          flag_false_all:    {
            opcode: 'flag-false-all'
          },
          flag_true:         {
            opcode: 'flag-true'
          },
          flag_true_all:     {
            opcode: 'flag-true-all'
          },
          defaults:          {
            opcode: 'defaults'
          }
        }

        def self.define
          # Generate accessors for all attributes and their aliases
          self::TESTER_FLOWLINE_ATTRS.each do |attr|
            writer = "#{attr}=".to_sym
            reader = attr.to_sym
            attr_reader attr.to_sym unless method_defined? reader
            attr_writer attr.to_sym unless method_defined? writer
          end

          ALIASES.each do |_alias, val|
            if val.is_a? Hash
              if ((self::TESTER_FLOWLINE_ATTRS.map(&:to_sym)) & val.keys) == val.keys
                writer = "#{_alias}=".to_sym
                unless method_defined? writer
                  define_method("#{_alias}=") do |v|
                    val.each do |k, _v|
                      myval = _v == :value ? v : _v
                      send("#{k}=", myval)
                    end
                  end
                end
              end
            else

              if self::TESTER_FLOWLINE_ATTRS.include? "#{val}"
                writer = "#{_alias}=".to_sym
                reader = _alias.to_sym
                unless method_defined? writer
                  define_method("#{_alias}=") do |v|
                    send("#{val}=", v)
                  end
                end
                unless method_defined? reader
                  define_method("#{_alias}") do
                    send(val)
                  end
                end
              end
            end
          end
        end

        def initialize(type, attrs = {})
          @ignore_missing_instance = attrs.delete(:instance_not_available)
          self.cz_setup = attrs.delete(:cz_setup)
          @type = type
          # Set the defaults
          DEFAULTS[@type.to_sym].each do |k, v|
            send("#{k}=", v) if respond_to?("#{k}=")
          end
          # Then the values that have been supplied
          attrs.each do |k, v|
            send("#{k}=", v) if respond_to?("#{k}=")
          end
          # override test numbers if diff-friendly output desired
          if Origen.tester.diff_friendly_output?
            self.tnum = 0
          end
        end

        def parameter=(value)
          if (@type == :test || @test == :cz) && !@ignore_missing_instance
            if value.is_a?(String) || value.is_a?(Symbol)
              fail "You must supply the actual test instance object for #{value} when adding it to the flow"
            end
          end
          @parameter = value
        end

        def parameter
          # When referring to the test instance take the opportunity to refresh the current
          # version of the test instance
          @parameter = Origen.interface.identity_map.current_version_of(@parameter)
        end

        # Returns the fully formatted flow line for insertion into a flow sheet
        def to_s
          l = "\t"
          self.class::TESTER_FLOWLINE_ATTRS.each do |attr|
            if attr == 'parameter'
              ins = parameter
              if ins.respond_to?(:name)
                l += "#{ins.name}"
              else
                l += "#{ins}"
              end
              if type == :cz && cz_setup
                l += " #{cz_setup}\t"
              else
                l += "\t"
              end
            else
              l += "#{send(attr)}\t"
            end
          end
          "#{l}"
        end

        def unless_enable=(*args)
        end
        alias_method :unless_enabled=, :unless_enable=

        def continue_pass
          self.result = 'Pass'
        end

        def debug_assume_pass
          self.debug_assume = 'Pass'
        end

        def debug_assume_fail
          self.debug_assume = 'Fail'
        end

        #          def debug_sites
        #            self.debug_sites = "All"
        #          end

        def set_flag_on_pass
          self.flag_pass = "#{id}_PASSED"
        end

        def set_flag_on_ran
          self.flag_pass = "#{id}_RAN"
        end

        def run_if_any_passed(parent)
          parent.continue_on_fail
          self.flag_true_any = parent.set_flag_on_pass
        end

        def run_if_all_passed(parent)
          parent.continue_on_fail
          self.flag_true_all = parent.set_flag_on_pass
        end

        def run_if_any_failed(parent)
          parent.continue_on_fail
          self.flag_true_any = parent.set_flag_on_fail
        end

        def run_if_all_failed(parent)
          parent.continue_on_fail
          self.flag_true_all = parent.set_flag_on_fail
        end

        def run_if_all_(args)
          # code
        end

        def id
          @id || "#{parameter}_#{unique_counter}"
        end

        def unique_counter
          @unique_counter ||= self.class.unique_counter
        end

        def self.unique_counter
          @ix ||= -1
          @ix += 1
        end

        def test?
          @type == :test
        end
      end
    end
  end
end
