module OrigenTesters
  module IGXLBasedTester
    class UltraFLEX
      require 'origen_testers/igxl_based_tester/base/test_instance'
      class TestInstance < Base::TestInstance
        # Attributes for each test instance line, first few are named directly
        TEST_INSTANCE_ATTRS = %w(
          test_name proc_type proc_name proc_called_as dc_category
          dc_selector ac_category ac_selector
          time_sets edge_sets pin_levels mixedsignal_timing overlay
        )

        # Give all UltraFLEX test instances the ability to contain limits, these will
        # be rendered to Use-limit lines in the flow
        attr_accessor :lo_limit, :hi_limit, :scale, :units, :defer_limits

        # Attributes for additional test instance arguments beyond those described above
        TEST_INSTANCE_EXTRA_ARGS = 130

        TEST_INSTANCE_ALIASES = {
          name:       :test_name,
          time_set:   :time_sets,
          timeset:    :time_sets,
          timesets:   :time_sets,

          other:      {
          },

          empty:      {
            arg_list:             :arg0,
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
            start_func_args:      :arg7,
            start_of_body_f_args: :arg7,
            pre_pat_func_args:    :arg8,
            pre_pat_f_args:       :arg8,
            pre_test_func_args:   :arg9,
            pre_test_f_args:      :arg9,
            post_test_func_args:  :arg10,
            post_test_f_args:     :arg10,
            post_pat_func_args:   :arg11,
            post_pat_f_args:      :arg11,
            end_func_args:        :arg12,
            end_of_body_f_args:   :arg12,
            utility_pins_1:       :arg13,
            utility_pins_0:       :arg14,
            init_lo:              :arg15,
            start_lo:             :arg15,
            init_hi:              :arg16,
            start_hi:             :arg16,
            init_hiz:             :arg17,
            start_hiz:            :arg17,
            float_pins:           :arg18,
            disable_pins:         :arg19
          },

          # Functional test instances
          functional: {
            arg_list:             :arg0,
            pattern:              :arg1,
            patterns:             :arg1,
            start_func:           :arg2,
            start_of_body_f:      :arg2,
            pre_pat_func:         :arg3,
            pre_pat_f:            :arg3,
            pre_test_func:        :arg4,
            pre_test_f:           :arg4,
            post_test_func:       :arg5,
            post_test_f:          :arg5,
            post_pat_func:        :arg6,
            post_pat_f:           :arg6,
            end_func:             :arg7,
            end_of_body_f:        :arg7,
            set_pass_fail:        :arg8,
            report_result:        :arg8,
            result_mode:          :arg9,
            init_lo:              :arg10,
            start_lo:             :arg10,
            init_hi:              :arg11,
            start_hi:             :arg11,
            init_hiz:             :arg12,
            start_hiz:            :arg12,
            disable_pins:         :arg13,
            float_pins:           :arg14,
            start_func_args:      :arg15,
            start_of_body_f_args: :arg15,
            pre_pat_func_args:    :arg16,
            pre_pat_f_args:       :arg16,
            pre_test_func_args:   :arg17,
            pre_test_f_args:      :arg17,
            post_test_func_args:  :arg18,
            post_test_f_args:     :arg18,
            post_pat_func_args:   :arg19,
            post_pat_f_args:      :arg19,
            end_func_args:        :arg20,
            end_of_body_f_args:   :arg20,
            utility_pins_1:       :arg21,
            utility_pins_0:       :arg22,
            pat_flag_func:        :arg23,
            pat_flag_f:           :arg23,
            PatFlagF:             :arg23,
            pat_flag_func_args:   :arg24,
            pat_flag_f_args:      :arg24,
            relay_mode:           :arg25,
            threading:            :arg26,
            match_all_sites:      :arg27,
            wait_flag1:           :arg28,
            wait_flag2:           :arg29,
            wait_flag3:           :arg30,
            wait_flag4:           :arg31,
            validating:           :arg32,
            wait_time:            :arg33,
            pattern_timeout:      :arg33,
            wait_time_domain:     :arg34,
            concurrent_mode:      :arg35
          },

          pin_pmu:    {
            arg_list:                :arg0,
            hsp_start:               :arg1,
            start_func:              :arg2,
            start_of_body_f:         :arg2,
            pre_pat_func:            :arg3,
            pre_pat_f:               :arg3,
            pre_test_func:           :arg4,
            pre_test_f:              :arg4,
            post_test_func:          :arg5,
            post_test_f:             :arg5,
            post_pat_func:           :arg6,
            post_pat_f:              :arg6,
            end_func:                :arg7,
            end_of_body_f:           :arg7,
            precond_pat:             :arg8,
            hold_state_pat:          :arg9,
            holdstate_pat:           :arg9,
            pattern:                 :arg9,
            pcp_stop:                :arg10,
            start_lo:                :arg11,
            init_lo:                 :arg11,
            start_hi:                :arg12,
            init_hi:                 :arg12,
            start_hiz:               :arg13,
            init_hiz:                :arg13,
            disable_pins:            :arg14,
            float_pins:              :arg15,
            pinlist:                 :arg16,
            pin:                     :arg16,
            pin_list:                :arg16,
            measure_mode:            :arg17,
            settling_time:           :arg18,
            force_cond_1:            :arg19,
            force_cond:              :arg19,
            force_condition:         :arg19,
            force_cond_2:            :arg20,
            relay_mode:              :arg21,
            start_func_args:         :arg22,
            start_of_body_f_args:    :arg22,
            pre_pat_func_args:       :arg23,
            pre_pat_f_args:          :arg23,
            pre_test_func_args:      :arg24,
            pre_test_f_args:         :arg24,
            post_test_func_args:     :arg25,
            post_test_f_args:        :arg25,
            post_pat_func_args:      :arg26,
            post_pat_f_args:         :arg26,
            end_func_args:           :arg27,
            end_of_body_f_args:      :arg27,
            pcp_start:               :arg28,
            pcp_check_pg:            :arg29,
            hsp_stop:                :arg30,
            hsp_check_pg:            :arg31,
            sampling_time:           :arg32,
            samples:                 :arg33,
            resume_pat:              :arg34,
            vcl:                     :arg35,
            vch:                     :arg36,
            utility_pins_1:          :arg37,
            utility_pins_0:          :arg38,
            wait_flag1:              :arg39,
            wait_flag2:              :arg40,
            wait_flag3:              :arg41,
            wait_flag4:              :arg42,
            validating:              :arg43,
            force_irange:            :arg44,
            meas_irange:             :arg45,
            wait_time_out:           :arg46,
            pcp_disable_alarm_check: :arg47,
            hsp_disable_alarm_check: :arg48,
            testing_in_series:       :arg49,
            background_meas_mode:    :arg50,
            background_force_irange: :arg51,
            background_meas_irange:  :arg52,
            background_force_cond:   :arg53,
            pins_alt:                :arg54,
            measure_mode_alt:        :arg55,
            force_cond_alt:          :arg56,
            force_irange_alt:        :arg57,
            meas_irange_alt:         :arg58
          }

        }

        TEST_INSTANCE_DEFAULTS = {
          empty:      {
            arg_list:       'StartOfBodyF,PrePatF,PreTestF,PostTestF,PostPatF,EndOfBodyF,StartOfBodyFArgs,PrePatFArgs,PreTestFArgs,PostTestFArgs,PostPatFArgs,EndOfBodyFArgs,Util1Pins,Util0Pins,DriveLoPins,DriveHiPins,DriveZPins,FloatPins,DisablePins',
            proc_type:      'VBT',
            proc_name:      'Empty_T',
            proc_called_as: 'Excel Macro'
          },
          other:      {
            proc_type:      'Other',
            proc_called_as: 'Excel Macro'
          },
          functional: {
            arg_list:        'Patterns,StartOfBodyF,PrePatF,PreTestF,PostTestF,PostPatF,EndOfBodyF,ReportResult,ResultMode,DriveLoPins,DriveHiPins,DriveZPins,DisablePins,FloatPins,StartOfBodyFArgs,PrePatFArgs,PreTestFArgs,PostTestFArgs,PostPatFArgs,EndOfBodyFArgs,Util1Pins,Util0Pins,PatFlagF,PatFlagFArgs,RelayMode,PatThreading,MatchAllSites,WaitFlagA,WaitFlagB,WaitFlagC,WaitFlagD,Validating_,PatternTimeout,WaitTimeDomain,ConcurrentMode',
            proc_type:       'VBT',
            proc_name:       'Functional_T',
            proc_called_as:  'Excel Macro',
            set_pass_fail:   1,
            relay_mode:      1,
            threading:       0,
            match_all_sites: 0,
            wait_flag1:      -2, # waitoff
            wait_flag2:      -2, # waitoff
            wait_flag3:      -2, # waitoff
            wait_flag4:      -2, # waitoff
            wait_time:       30
          },
          pin_pmu:    {
            arg_list:       'HspStartLabel,StartOfBodyF,PrePatF,PreTestF,PostTestF,PostPatF,EndOfBodyF,PreconditionPat,HoldStatePat,PcpStopLabel,DriveLoPins,DriveHiPins,DriveZPins,DisablePins,FloatPins,Pins,MeasureMode,SettlingTime,ForceCond1,ForceCond2,RelayMode,StartOfBodyFArgs,PrePatFArgs,PreTestFArgs,PostTestFArgs,PostPatFArgs,EndOfBodyFArgs,PcpStartLabel,PcpCheckPatGen,HspStopLabel,HspCheckPatGen,SamplingTime,SampleCount,HspResumePat,VClampLo,VClampHi,Util1Pins,Util0Pins,WaitFlagA,WaitFlagB,WaitFlagC,WaitFlagD,Validating_,ForceIRange,MeasIRange,PatternTimeout,PcpDisableAlarmCheck,HspDisableAlarmCheck,TestingInSeries,BackgroundMeasureMode,BackgroundForceIRange,BackgroundMeasIRange,BackgroundForceCond,PinsAlt,MeasureModeAlt,ForceCondAlt,ForceIRangeAlt,MeasIRangeAlt',
            proc_type:      'VBT',
            proc_name:      'PinPmu_T',
            proc_called_as: 'Excel Macro',
            wait_flag1:     -2, # waitoff
            wait_flag2:     -2, # waitoff
            wait_flag3:     -2, # waitoff
            wait_flag4:     -2, # waitoff
          }
        }

        # Generate the instance method definitions based on the above
        define

        # Set the cpu wait flags for the given test instance
        #   instance.set_wait_flags(:a)
        #   instance.set_wait_flags(:a, :c)
        # assumes set flag means to set it high (waithi = -1 )
        # assumes clr flag means to set it off (waitoff = -2)
        # does not yet support waitlo = 0
        def set_wait_flags(*flags)
          a = (flags.include?(:a) || flags.include?(:a)) ? '-1' : '-2'
          b = (flags.include?(:b) || flags.include?(:b)) ? '-1' : '-2'
          c = (flags.include?(:c) || flags.include?(:c)) ? '-1' : '-2'
          d = (flags.include?(:d) || flags.include?(:d)) ? '-1' : '-2'
          self.wait_flag1 = a
          self.wait_flag2 = b
          self.wait_flag3 = c
          self.wait_flag4 = d
          self
        end
      end
    end
  end
end
