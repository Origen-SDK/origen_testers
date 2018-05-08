module OrigenTesters
  module SmartestBasedTester
    class V93K
      require 'origen_testers/smartest_based_tester/base/test_suite'
      class TestSuite < Base::TestSuite
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
          if attr == 'name' || attr == 'pattern'
            attr_reader attr.to_sym
          else
            attr_accessor attr.to_sym
          end
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
      end
    end
  end
end
