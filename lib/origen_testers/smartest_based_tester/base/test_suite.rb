module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestSuite
        attr_accessor :meta

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
          self.class::DEFAULTS.each do |k, v|
            send("#{k}=", v)
          end
          # Then the values that have been supplied
          attrs.each do |k, v|
            send("#{k}=", v) if respond_to?("#{k}=") && k.to_sym != :name
          end
        end

        def smt8?
          tester.smt8?
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
          m = meta || {}
          m['Test'] = name
          m['Test Name'] ||= try(:test_name)
          m
        end

        def extract_atp_attributes(options)
          options[:limits] ||= limits.to_atp_attributes
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
          f << 'force_serial' if force_serial
          f.empty? ? f : f.join(', ')
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
