module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestSuite
        attr_accessor :meta

        ATTRS =
          %w(name
             comment

             timing_equation timing_spec timing_set
             level_equation level_spec level_set
             analog_set
             pattern
             context
             test_type
             test_method

             test_number
             test_level

             bypass
             set_pass
             set_fail
             hold
             hold_on_fail
             output_on_pass
             output_on_fail
             pass_value
             fail_value
             per_pin_on_pass
             per_pin_on_fail
             log_mixed_signal_waveform
             fail_per_label
             ffc_enable
             log_first
             ffv_enable
             frg_enable
             hardware_dsp_disable
          )

        ALIASES = {
          tim_equ_set:     :timing_equation,
          tim_spec_set:    :timing_spec,
          timset:          :timing_set,
          timeset:         :timing_set,
          time_set:        :timing_set,
          lev_equ_set:     :level_equation,
          lev_spec_set:    :level_spec,
          levset:          :level_set,
          levels:          :level_set,
          pin_levels:      :level_set,
          anaset:          :analog_set,
          test_num:        :test_number,
          test_function:   :test_method,
          value_on_pass:   :pass_value,
          value_on_fail:   :fail_value,
          seqlbl:          :pattern,
          mx_waves_enable: :log_mixed_signal_waveform,
          hw_dsp_disable:  :hardware_dsp_disable,
          ffc_on_fail:     :log_first
        }

        DEFAULTS = {
          output_on_pass:  true,
          output_on_fail:  true,
          pass_value:      true,
          fail_value:      true,
          per_pin_on_pass: true,
          per_pin_on_fail: true
        }

        # Generate accessors for all attributes and their aliases
        ATTRS.each do |attr|
          attr_accessor attr.to_sym
        end

        # Define the aliases
        ALIASES.each do |_alias, val|
          define_method("#{_alias}=") do |v|
            send("#{val}=", v)
          end
          define_method("#{_alias}") do
            send(val)
          end
        end

        def initialize(name, attrs = {})
          @name = name
          if interface.unique_test_names == :signature
            if interface.flow.sig
              @name = "#{name}_#{interface.flow.sig}"
            end
          elsif interface.unique_test_names == :flowname || interface.unique_test_names == :flow_name
            @name = "#{name}_#{interface.flow.name.to_s.symbolize}"
          elsif interface.unique_test_names == :preflowname || interface.unique_test_names == :pre_flow_name
            @name = "#{interface.flow.name.to_s.symbolize}_#{name}"
          elsif interface.unique_test_names
            utn_string = interface.unique_test_names.to_s
            if utn_string =~ /^prepend_/
              utn_string = utn_string.gsub(/^prepend_/, '')
              @name = "#{utn_string}_#{name}"
            else
              utn_string = utn_string.gsub(/^append_/, '')
              @name = "#{name}_#{utn_string}"
            end
          end
          # Set the defaults
          DEFAULTS.each do |k, v|
            send("#{k}=", v)
          end
          # Then the values that have been supplied
          attrs.each do |k, v|
            send("#{k}=", v) if respond_to?("#{k}=") && k.to_sym != :name
          end
        end

        def pattern=(name)
          Origen.interface.record_pattern_reference(name) if name
          @pattern = name
        end

        def inspect
          "<TestSuite: #{name}>"
        end

        # The name is immutable once the test_suite is created, this will raise an error when called
        def name=(val, options = {})
          fail 'Once assigned the name of a test suite cannot be changed!'
        end

        def lines
          if pattern
            burst = $tester.multiport ? "#{$tester.multiport_name(pattern)}" : "#{pattern}"
          end
          l = []
          l << "  comment = \"#{comment}\";" if comment
          l << "  ffc_on_fail = #{wrap_if_string(log_first)};" if log_first
          l << "  local_flags = #{flags};"
          l << '  override = 1;'
          l << "  override_anaset = #{wrap_if_string(analog_set)};" if analog_set
          l << "  override_lev_equ_set = #{wrap_if_string(level_equation)};" if level_equation
          l << "  override_lev_spec_set = #{wrap_if_string(level_spec)};" if level_spec
          l << "  override_levset = #{wrap_if_string(level_set)};" if level_set
          l << "  override_seqlbl = #{wrap_if_string(burst)};" if pattern
          l << "  override_test_number = #{test_number};" if test_number
          l << "  override_testf = #{test_method.id};" if test_method
          l << "  override_tim_equ_set = #{wrap_if_string(timing_equation)};" if timing_equation
          l << "  override_tim_spec_set = #{wrap_if_string(timing_spec)};" if timing_spec
          l << "  override_timset = #{wrap_if_string(timing_set)};" if timing_set
          l << '  site_control = "parallel:";'
          l << '  site_match = 2;'
          l << "  test_level = #{test_level};" if test_level
          l
        end

        def method_missing(method, *args, &block)
          if test_method && test_method.respond_to?(method)
            test_method.send(method, *args, &block)
          else
            super
          end
        end

        def respond_to?(method)
          (test_method && test_method.respond_to?(method)) || super
        end

        def interface
          Origen.interface
        end

        def to_meta
          meta || {}
        end

        private

        def flags
          f = []
          f << 'bypass' if bypass
          f << 'set_pass' if set_pass
          f << 'set_fail' if set_fail
          f << 'hold' if hold
          f << 'hold_on_fail' if hold_on_fail
          f << 'output_on_pass' if output_on_pass
          f << 'output_on_fail' if output_on_fail
          f << 'value_on_pass' if pass_value
          f << 'value_on_fail' if fail_value
          f << 'per_pin_on_pass' if per_pin_on_pass
          f << 'per_pin_on_fail' if per_pin_on_fail
          f << 'mx_waves_enable' if log_mixed_signal_waveform
          f << 'fail_per_label' if fail_per_label
          f << 'ffc_enable' if ffc_enable
          f << 'ffv_enable' if ffv_enable
          f << 'frg_enable' if frg_enable
          f << 'hw_dsp_disable' if hardware_dsp_disable
          f.join(', ')
        end

        def wrap_if_string(value)
          if value.is_a?(String)
            "\"#{value}\""
          else
            value
          end
        end
      end
    end
  end
end
