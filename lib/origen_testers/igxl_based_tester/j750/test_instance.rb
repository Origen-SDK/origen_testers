module OrigenTesters
  module IGXLBasedTester
    class J750
      require 'origen_testers/igxl_based_tester/base/test_instance'
      class TestInstance < Base::TestInstance
        # Attributes for each test instance line, first few are named directly
        TEST_INSTANCE_ATTRS = %w(
          test_name proc_type proc_name proc_called_as dc_category
          dc_selector ac_category ac_selector
          time_sets edge_sets pin_levels overlay
        )

        # Attributes for additional test instance arguments beyond those described above
        TEST_INSTANCE_EXTRA_ARGS = 80

        TEST_INSTANCE_ALIASES = {
          name:             :test_name,
          time_set:         :time_sets,
          timeset:          :time_sets,
          timesets:         :time_sets,

          other:            {},

          empty:            {
            start_func:           :arg0,
            start_of_body_f:      :arg0,
            pre_pat_func:         :arg1,
            pre_pat_f:            :arg1,
            pre_test_func:        :arg2,
            pre_test_f:           :arg2,
            post_test_func:       :arg3,
            post_test_f:          :arg3,
            post_pat_func:        :arg4,
            post_pat_f:           :arg4,
            end_func:             :arg5,
            end_of_body_f:        :arg5,
            start_func_args:      :arg6,
            start_of_body_f_args: :arg6,
            pre_pat_func_args:    :arg7,
            pre_pat_f_args:       :arg7,
            pre_test_func_args:   :arg8,
            pre_test_f_args:      :arg8,
            post_test_func_args:  :arg9,
            post_test_f_args:     :arg9,
            post_pat_func_args:   :arg10,
            post_pat_f_args:      :arg10,
            end_func_args:        :arg11,
            end_of_body_f_args:   :arg11,
            utility_pins_1:       :arg12,
            utility_pins_0:       :arg13,
            init_lo:              :arg14,
            start_lo:             :arg14,
            init_hi:              :arg15,
            start_hi:             :arg15,
            init_hiz:             :arg16,
            start_hiz:            :arg16,
            float_pins:           :arg17
          },

          # Functional test instances
          functional:       {
            pattern:              :arg0,
            patterns:             :arg0,
            start_func:           :arg1,
            start_of_body_f:      :arg1,
            pre_pat_func:         :arg2,
            pre_pat_f:            :arg2,
            pre_test_func:        :arg3,
            pre_test_f:           :arg3,
            post_test_func:       :arg4,
            post_test_f:          :arg4,
            post_pat_func:        :arg5,
            post_pat_f:           :arg5,
            end_func:             :arg6,
            end_of_body_f:        :arg6,
            set_pass_fail:        :arg7,
            init_lo:              :arg8,
            start_lo:             :arg8,
            init_hi:              :arg9,
            start_hi:             :arg9,
            init_hiz:             :arg10,
            start_hiz:            :arg10,
            float_pins:           :arg11,
            start_func_args:      :arg13,
            start_of_body_f_args: :arg13,
            pre_pat_func_args:    :arg14,
            pre_pat_f_args:       :arg14,
            pre_test_func_args:   :arg15,
            pre_test_f_args:      :arg15,
            post_test_func_args:  :arg16,
            post_test_f_args:     :arg16,
            post_pat_func_args:   :arg17,
            post_pat_f_args:      :arg17,
            end_func_args:        :arg18,
            end_of_body_f_args:   :arg18,
            utility_pins_1:       :arg19,
            utility_pins_0:       :arg20,
            wait_flags:           :arg21,
            wait_time:            :arg22,
            pattern_timeout:      :arg22,
            pat_flag_func:        :arg23,
            pat_flag_f:           :arg23,
            PatFlagF:             :arg23,
            pat_flag_func_args:   :arg24,
            pat_flag_f_args:      :arg24,
            relay_mode:           :arg25,
            threading:            :arg26,
            match_all_sites:      :arg27,
            capture_mode:         :arg30,
            capture_what:         :arg31,
            capture_memory:       :arg32,
            capture_size:         :arg33,
            datalog_mode:         :arg34,
            data_type:            :arg35
          },

          board_pmu:        {
            hsp_start:            :arg0,
            start_func:           :arg1,
            start_of_body_f:      :arg1,
            pre_pat_func:         :arg2,
            pre_pat_f:            :arg2,
            pre_test_func:        :arg3,
            pre_test_f:           :arg3,
            post_test_func:       :arg4,
            post_test_f:          :arg4,
            post_pat_func:        :arg5,
            post_pat_f:           :arg5,
            end_func:             :arg6,
            end_of_body_f:        :arg6,
            precond_pat:          :arg7,
            hold_state_pat:       :arg8,
            holdstate_pat:        :arg8,
            pattern:              :arg8,
            pcp_stop:             :arg9,
            wait_flags:           :arg10,
            start_lo:             :arg11,
            init_lo:              :arg11,
            start_hi:             :arg12,
            init_hi:              :arg12,
            start_hiz:            :arg13,
            init_hiz:             :arg13,
            float_pins:           :arg14,
            pinlist:              :arg15,
            pin:                  :arg15,
            pin_list:             :arg15,
            measure_mode:         :arg16,
            irange:               :arg17,
            clamp:                :arg18,
            vrange:               :arg19,
            sampling_time:        :arg20,
            samples:              :arg21,
            settling_time:        :arg22,
            hi_lo_lim_valid:      :arg23,
            hi_lo_limit_valid:    :arg23,
            hi_limit:             :arg24,
            lo_limit:             :arg25,
            force_cond_1:         :arg26,
            force_cond:           :arg26,
            force_condition:      :arg26,
            force_cond_2:         :arg27,
            gang_pins_tested:     :arg28,
            relay_mode:           :arg29,
            wait_time_out:        :arg30,
            start_func_args:      :arg31,
            start_of_body_f_args: :arg31,
            pre_pat_func_args:    :arg32,
            pre_pat_f_args:       :arg32,
            pre_test_func_args:   :arg33,
            pre_test_f_args:      :arg33,
            post_test_func_args:  :arg34,
            post_test_f_args:     :arg34,
            post_pat_func_args:   :arg35,
            post_pat_f_args:      :arg35,
            end_func_args:        :arg36,
            end_of_body_f_args:   :arg36,
            pcp_start:            :arg37,
            pcp_check_pg:         :arg38,
            hsp_stop:             :arg39,
            hsp_check_pg:         :arg40,
            resume_pat:           :arg41,
            utility_pins_1:       :arg42,
            utility_pins_0:       :arg43,
            pre_charge_enable:    :arg44,
            pre_charge:           :arg45,
            threading:            :arg46
          },

          pin_pmu:          {
            hsp_start:            :arg0,
            start_func:           :arg1,
            start_of_body_f:      :arg1,
            pre_pat_func:         :arg2,
            pre_pat_f:            :arg2,
            pre_test_func:        :arg3,
            pre_test_f:           :arg3,
            post_test_func:       :arg4,
            post_test_f:          :arg4,
            post_pat_func:        :arg5,
            post_pat_f:           :arg5,
            end_func:             :arg6,
            end_of_body_f:        :arg6,
            precond_pat:          :arg7,
            hold_state_pat:       :arg8,
            holdstate_pat:        :arg8,
            pattern:              :arg8,
            pcp_stop:             :arg9,
            wait_flags:           :arg10,
            start_lo:             :arg11,
            init_lo:              :arg11,
            start_hi:             :arg12,
            init_hi:              :arg12,
            start_hiz:            :arg13,
            init_hiz:             :arg13,
            float_pins:           :arg14,
            pinlist:              :arg15,
            pin:                  :arg15,
            pin_list:             :arg15,
            measure_mode:         :arg16,
            irange:               :arg17,
            settling_time:        :arg18,
            hi_lo_lim_valid:      :arg19,
            hi_lo_limit_valid:    :arg19,
            hi_limit:             :arg20,
            lo_limit:             :arg21,
            force_cond_1:         :arg22,
            force_cond:           :arg22,
            force_condition:      :arg22,
            force_cond_2:         :arg23,
            fload:                :arg24,
            relay_mode:           :arg25,
            wait_time_out:        :arg26,
            start_func_args:      :arg27,
            start_of_body_f_args: :arg27,
            pre_pat_func_args:    :arg28,
            pre_pat_f_args:       :arg28,
            pre_test_func_args:   :arg29,
            pre_test_f_args:      :arg29,
            post_test_func_args:  :arg30,
            post_test_f_args:     :arg30,
            post_pat_func_args:   :arg31,
            post_pat_f_args:      :arg31,
            end_func_args:        :arg32,
            end_of_body_f_args:   :arg32,
            pcp_start:            :arg33,
            pcp_check_pg:         :arg34,
            hsp_stop:             :arg35,
            hsp_check_pg:         :arg36,
            sampling_time:        :arg37,
            samples:              :arg38,
            resume_pat:           :arg39,
            vcl:                  :arg40,
            vch:                  :arg41,
            utility_pins_1:       :arg42,
            utility_pins_0:       :arg43,
            pre_charge_enable:    :arg44,
            pre_charge:           :arg45,
            threading:            :arg46
          },

          apmu_powersupply: {
            precond_pat:              :arg0,
            pre_cond_pat:             :arg0,
            start_func:               :arg1,
            start_of_body_f:          :arg1,
            pre_pat_func:             :arg2,
            pre_pat_f:                :arg2,
            pre_test_func:            :arg3,
            pre_test_f:               :arg3,
            post_test_func:           :arg4,
            post_test_f:              :arg4,
            post_pat_func:            :arg5,
            post_pat_f:               :arg5,
            end_func:                 :arg6,
            end_of_body_f:            :arg6,
            pattern:                  :arg7,
            hold_state_pat:           :arg7,
            holdstate_pat:            :arg7,
            wait_flags:               :arg8,
            wait_time_out:            :arg9,
            start_lo:                 :arg10,
            start_init_lo:            :arg10,
            init_lo:                  :arg10,
            start_hi:                 :arg11,
            start_init_hi:            :arg11,
            init_hi:                  :arg11,
            start_hiz:                :arg12,
            start_init_hiz:           :arg12,
            init_hiz:                 :arg12,
            float_pins:               :arg13,
            irange:                   :arg14,
            sampling_time:            :arg15,
            samples:                  :arg16,
            settling_time:            :arg17,
            hi_lo_lim_valid:          :arg18,
            hi_lo_limit_valid:        :arg18,
            hi_limit:                 :arg19,
            lo_limit:                 :arg20,
            force_cond_1:             :arg21,
            force_cond:               :arg21,
            force_condition:          :arg21,
            force_condition_1:        :arg21,
            force_cond_2:             :arg22,
            force_condition_2:        :arg22,
            power_pins:               :arg23,
            pins:                     :arg23,
            pin:                      :arg23,
            force_source:             :arg24,
            pcp_start:                :arg25,
            pcp_stop:                 :arg26,
            start_func_args:          :arg27,
            start_of_body_f_args:     :arg27,
            pre_pat_func_args:        :arg28,
            pre_pat_f_args:           :arg28,
            pre_test_func_args:       :arg29,
            pre_test_f_args:          :arg29,
            post_test_func_args:      :arg30,
            post_test_f_args:         :arg30,
            post_pat_func_args:       :arg31,
            post_pat_f_args:          :arg31,
            end_func_args:            :arg32,
            end_of_body_f_args:       :arg32,
            hsp_start:                :arg33,
            hsp_stop:                 :arg34,
            pcp_check_pg:             :arg35,
            clamp:                    :arg36,
            hsp_check_pg:             :arg37,
            resume_pat:               :arg38,
            relay_mode:               :arg39,
            utility_pins_1:           :arg40,
            utility_pins_0:           :arg41,
            test_control:             :arg42,
            serialize_meas:           :arg43,
            serialize_meas_func:      :arg44,
            serialize_meas_f:         :arg44,
            serialize_meas_func_args: :arg45,
            serialize_meas_f_args:    :arg45
          },

          powersupply:      {
            precond_pat:              :arg0,
            pre_cond_pat:             :arg0,
            start_func:               :arg1,
            start_of_body_f:          :arg1,
            pre_pat_func:             :arg2,
            pre_pat_f:                :arg2,
            pre_test_func:            :arg3,
            pre_test_f:               :arg3,
            post_test_func:           :arg4,
            post_test_f:              :arg4,
            post_pat_func:            :arg5,
            post_pat_f:               :arg5,
            end_func:                 :arg6,
            end_of_body_f:            :arg6,
            pattern:                  :arg7,
            hold_state_pat:           :arg7,
            holdstate_pat:            :arg7,
            wait_flags:               :arg8,
            wait_time_out:            :arg9,
            start_lo:                 :arg10,
            start_init_lo:            :arg10,
            init_lo:                  :arg10,
            start_hi:                 :arg11,
            start_init_hi:            :arg11,
            init_hi:                  :arg11,
            start_hiz:                :arg12,
            start_init_hiz:           :arg12,
            init_hiz:                 :arg12,
            float_pins:               :arg13,
            irange:                   :arg14,
            sampling_time:            :arg15,
            samples:                  :arg16,
            settling_time:            :arg17,
            hi_lo_lim_valid:          :arg18,
            hi_lo_limit_valid:        :arg18,
            hi_limit:                 :arg19,
            lo_limit:                 :arg20,
            force_cond_1:             :arg21,
            force_cond:               :arg21,
            force_condition:          :arg21,
            force_condition_1:        :arg21,
            force_cond_2:             :arg22,
            force_condition_2:        :arg22,
            power_pins:               :arg23,
            pins:                     :arg23,
            pin:                      :arg23,
            force_source:             :arg24,
            pcp_start:                :arg25,
            pcp_stop:                 :arg26,
            start_func_args:          :arg27,
            start_of_body_f_args:     :arg27,
            pre_pat_func_args:        :arg28,
            pre_pat_f_args:           :arg28,
            pre_test_func_args:       :arg29,
            pre_test_f_args:          :arg29,
            post_test_func_args:      :arg30,
            post_test_f_args:         :arg30,
            post_pat_func_args:       :arg31,
            post_pat_f_args:          :arg31,
            end_func_args:            :arg32,
            end_of_body_f_args:       :arg32,
            hsp_start:                :arg33,
            hsp_stop:                 :arg34,
            pcp_check_pg:             :arg35,
            clamp:                    :arg36,
            hsp_check_pg:             :arg37,
            resume_pat:               :arg38,
            relay_mode:               :arg39,
            utility_pins_1:           :arg40,
            utility_pins_0:           :arg41,
            test_control:             :arg42,
            serialize_meas:           :arg43,
            serialize_meas_func:      :arg44,
            serialize_meas_f:         :arg44,
            serialize_meas_func_args: :arg45,
            serialize_meas_f_args:    :arg45,
            precond_pat_clamp:        :arg46,
            threading:                :arg47
          },

          mto_memory:       {
            patterns:                  :arg0,
            pattern:                   :arg0,
            start_func:                :arg1,
            start_of_body_f:           :arg1,
            pre_pat_func:              :arg2,
            pre_pat_f:                 :arg2,
            pre_test_func:             :arg3,
            pre_test_f:                :arg3,
            post_test_func:            :arg4,
            post_test_f:               :arg4,
            post_pat_func:             :arg5,
            post_pat_f:                :arg5,
            end_of_body_func:          :arg6,
            end_of_body_f:             :arg6,
            set_pass_fail:             :arg7,
            init_lo:                   :arg8,
            start_lo:                  :arg8,
            init_hi:                   :arg9,
            start_hi:                  :arg9,
            init_hiz:                  :arg10,
            start_hiz:                 :arg10,
            float_pins:                :arg11,
            start_of_body_func_args:   :arg12,
            start_of_body_f_args:      :arg12,
            pre_pat_func_args:         :arg13,
            pre_pat_f_args:            :arg13,
            pre_test_func_args:        :arg14,
            pre_test_f_args:           :arg14,
            post_test_func_args:       :arg15,
            post_test_f_args:          :arg15,
            post_pat_f_args:           :arg16,
            end_of_body_func_args:     :arg17,
            end_of_body_f_args:        :arg17,
            utility_pins_1:            :arg18,
            utility_pins_0:            :arg19,
            wait_flags:                :arg20,
            wait_time_out:             :arg21,
            PatFlagF:                  :arg22,
            pat_flag_f:                :arg22,
            pat_flag_func_args:        :arg23,
            pat_flag_f_args:           :arg23,
            relay_mode:                :arg24,
            x_enable_mask:             :arg29,
            x_shift_direction:         :arg30,
            x_shift_input:             :arg31,
            y_enable_mask:             :arg36,
            y_shift_direction:         :arg37,
            y_shift_input:             :arg38,
            dga:                       :arg39,
            dgb:                       :arg40,
            dgc:                       :arg41,
            dgd:                       :arg42,
            dg_enable_mask:            :arg43,
            dg_shift_direction:        :arg44,
            dg_shift_input:            :arg45,
            x_coincidence_enable_mask: :arg46,
            y_coincidence_enable_mask: :arg47,
            two_bit_dg_setup:          :arg48,
            x_scramble_algorithm:      :arg49,
            y_scramble_algorithm:      :arg50,
            topo_inversion_algorithm:  :arg51,
            utility_counter_a:         :arg52,
            utility_counter_b:         :arg53,
            utility_counter_c:         :arg54,
            dut_data_source:           :arg55,
            scramble_addr:             :arg56,
            speed_mode:                :arg57,
            resource_map:              :arg58,
            receive_data:              :arg59,
            data_to_capture:           :arg60,
            capture_marker:            :arg61,
            enable_wrapping:           :arg62,
            capture_scrambled_address: :arg63,
            mapmem_0_input_set:        :arg64,
            mapmem_1_input_set:        :arg65,
            threading:                 :arg69,
            match_all_sites:           :arg70
          }
        }

        TEST_INSTANCE_DEFAULTS = {
          empty:            {
            proc_type:      'IG-XL Template',
            proc_name:      'Empty_T',
            proc_called_as: 'Excel Macro'
          },
          other:            {
            proc_type:      'Other',
            proc_called_as: 'Excel Macro'
          },
          functional:       {
            proc_type:       'IG-XL Template',
            proc_name:       'Functional_T',
            proc_called_as:  'VB DLL',
            set_pass_fail:   1,
            wait_flags:      'XXXX',
            wait_time:       30,
            relay_mode:      1,
            threading:       0,
            match_all_sites: 0,
            capture_mode:    0,
            capture_what:    0,
            capture_memory:  0,
            capture_size:    256,
            datalog_mode:    0,
            data_type:       0
          },
          board_pmu:        {
            proc_type:        'IG-XL Template',
            proc_name:        'BoardPmu_T',
            proc_called_as:   'VB DLL',
            wait_flags:       'XXXX',
            measure_mode:     1,
            irange:           5,
            vrange:           3,
            settling_time:    0,
            hi_lo_lim_valid:  3,
            gang_pins_tested: 0,
            relay_mode:       0,
            wait_time_out:    30,
            pcp_check_pg:     1,
            hsp_check_pg:     1,
            resume_pat:       0,
            threading:        0
          },
          pin_pmu:          {
            proc_type:       'IG-XL Template',
            proc_name:       'PinPmu_T',
            proc_called_as:  'VB DLL',
            wait_flags:      'XXXX',
            measure_mode:    1,
            irange:          2,
            settling_time:   0,
            hi_lo_lim_valid: 3,
            fload:           0,
            relay_mode:      0,
            wait_time_out:   30,
            pcp_check_pg:    1,
            hsp_check_pg:    1,
            resume_pat:      0,
            threading:       0
          },
          apmu_powersupply: {
            proc_type:       'IG-XL Template',
            proc_name:       'ApmuPowerSupply_T',
            proc_called_as:  'VB DLL',
            wait_flags:      'XXXX',
            irange:          1,
            settling_time:   0,
            hi_lo_lim_valid: 3,
            relay_mode:      0,
            wait_time_out:   30,
            pcp_check_pg:    1,
            hsp_check_pg:    1,
            resume_pat:      0,
            test_control:    0
          },
          powersupply:      {
            proc_type:       'IG-XL Template',
            proc_name:       'PowerSupply_T',
            proc_called_as:  'VB DLL',
            wait_flags:      'XXXX',
            irange:          1,
            settling_time:   0,
            hi_lo_lim_valid: 3,
            relay_mode:      0,
            wait_time_out:   30,
            pcp_check_pg:    1,
            hsp_check_pg:    1,
            resume_pat:      0,
            test_control:    0
          },
          mto_memory:       {
            proc_type:                 'IG-XL Template',
            proc_name:                 'MtoMemory_T',
            proc_called_as:            'VB DLL',
            set_pass_fail:             1,
            wait_flags:                'XXXX',
            wait_time:                 30,
            relay_mode:                1,
            threading:                 0,
            match_all_sites:           0,
            dut_data_source:           0,
            scramble_addr:             0,
            speed_mode:                0,
            resource_map:              'MAP_1M_2BIT',
            receive_data:              0,
            data_to_capture:           1,
            capture_marker:            1,
            enable_wrapping:           0,
            capture_scrambled_address: 0,
            mapmem_0_input_set:        'Map_By16',
            mapmem_1_input_set:        'Map_By16',
            x_scramble_algorithm:      'X_NO_SCRAMBLE',
            y_scramble_algorithm:      'Y_NO_SCRAMBLE',
            topo_inversion_algorithm:  'NO_TOPO',
            x_shift_direction:         0,
            x_shift_input:             0,
            y_shift_direction:         0,
            y_shift_input:             0,
            x_coincidence_enable_mask: 0,
            y_coincidence_enable_mask: 0,
            dg_shift_direction:        0,
            dg_shift_input:            0
          }
        }

        # Generate the instance method definitions based on the above
        define

        # Set the cpu wait flags for the given test instance
        #   instance.set_wait_flags(:a)
        #   instance.set_wait_flags(:a, :c)
        def set_wait_flags(*flags)
          a = (flags.include?(:a) || flags.include?(:a)) ? '1' : 'X'
          b = (flags.include?(:b) || flags.include?(:b)) ? '1' : 'X'
          c = (flags.include?(:c) || flags.include?(:c)) ? '1' : 'X'
          d = (flags.include?(:d) || flags.include?(:d)) ? '1' : 'X'
          self.wait_flags = d + c + b + a
          self
        end

        # Set and enable the pre-charge voltage of a parametric test instance.
        def set_pre_charge(val)
          if val
            self.pre_charge_enable = 1
            self.pre_charge = val
          else
            self.pre_charge_enable = 0
          end
          self
        end
        alias_method :set_precharge, :set_pre_charge

        # Returns a hash containing key meta data about the test instance, this is
        # intended to be used in documentation
        def to_meta
          return @meta if @meta

          m = { 'Test' => name,
                'Type' => type
          }
          if type == :functional
            m['Pattern'] = pattern
          elsif type == :board_pmu || type == :pin_pmu
            m['Measure'] = fvmi? ? 'current' : 'voltage'
            if hi_lo_limit_valid & 2 != 0
              m['Hi'] = hi_limit
            end
            if hi_lo_limit_valid & 1 != 0
              m['Lo'] = lo_limit
            end
            m['Hi'] = hi_limit
            m['Lo'] = lo_limit
            if force_cond
              m['Force'] = force_cond
            end
          elsif type == :powersupply
            if hi_lo_limit_valid & 2 != 0
              m['Hi'] = hi_limit
            end
            if hi_lo_limit_valid & 1 != 0
              m['Lo'] = lo_limit
            end
            m['Hi'] = hi_limit
            m['Lo'] = lo_limit
            if force_cond
              m['Force'] = force_cond
            end
          end
          m['DC'] = "#{dc_category} (#{dc_selector})"
          m['AC'] = "#{ac_category} (#{ac_selector})"
          m
        end

        # Set the meaure mode of a parametric test instance, either:
        # * :voltage / :fimv
        # * :current / :fvmi
        def set_measure_mode(mode)
          if mode == :current || mode == :fvmi
            self.measure_mode = 0
          elsif mode == :voltage || mode == :fimv
            self.measure_mode = 1
          else
            fail "Unknown measure mode: #{mode}"
          end
        end

        # Set and enable the hi limit of a parametric test instance, passing in
        # nil or false as the lim parameter will disable the hi limit.
        def set_hi_limit(lim)
          if lim
            if $tester.j750?
              self.hi_lo_limit_valid = hi_lo_limit_valid | 2
            end
            self.hi_limit = lim
          else
            if $tester.j750?
              self.hi_lo_limit_valid = hi_lo_limit_valid & 1
            end
          end
          self
        end
        alias_method :hi_limit=, :set_hi_limit

        # Set and enable the hi limit of a parametric test instance, passing in
        # nil or false as the lim parameter will disable the hi limit.
        def set_lo_limit(lim)
          if lim
            if $tester.j750?
              self.hi_lo_limit_valid = hi_lo_limit_valid | 1
            end
            self.lo_limit = lim
          else
            if $tester.j750?
              self.hi_lo_limit_valid = hi_lo_limit_valid & 2
            end
          end
          self
        end
        alias_method :lo_limit=, :set_lo_limit
      end
    end
  end
end
