module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestMethods
        class DcTml < BaseTml
          TEST_METHODS = {
            continuity:        {
              pinlist:               [:string, '@'],
              test_current:          [:current, 10.uA],
              settling_time:         [:time, 1.ms],
              measurement_mode:      [:string, 'PPMUpar', %w(PPMUpar ProgLoad)],
              polarity:              [:string, 'SPOL', ['SPOL' 'BPOL']],
              precharge_to_zero_vol: [:string, 'ON', %w(ON OFF)],
              test_name:             [:string, 'passVolt_mv'],
              output:                [:string, 'None', %w(None ReportUI ShowFailOnly)]
            },
            dps_connectivity:  {
              dps_pins:  [:string, '@'],
              test_name: [:string, 'DPS_ForceSense'],
              output:    [:string, 'None', %w(None ReportUI ShowFailOnly)]
            },
            dps_status:        {
              dps_pins:         [:string, '@'],
              constant_current: [:string, 'OFF', %w(ON OFF)],
              unregulated:      [:string, 'OFF', %w(ON OFF)],
              over_voltage:     [:string, 'OFF', %w(ON OFF)],
              over_power_temp:  [:string, 'OFF', %w(ON OFF)],
              test_name:        [:string, 'DPS_Status'],
              output:           [:string, 'None', %w(None ReportUI ShowFailOnly)]
            },
            dvm:               {
              class_name:    'DVM',
              pinlist:       [:string, '@'],
              settling_time: [:time, 0],
              measure_mode:  [:string, 'PPMUpar', %w(PPMUpar ProgLoad)],
              test_name:     [:string, 'passVoltageLimit_mV'],
              output:        [:string, 'None', %w(None ReportUI ShowFailOnly)]
            },
            general_pmu:       {
              class_name:        'GeneralPMU',
              pinlist:           [:string, '@'],
              force_mode:        [:string, 'VOLT', %w(VOLT CURR)],
              force_value:       [:force_mode, 3800.mV],
              spmu_clamp:        [:current, 0],
              precharge:         [:string, 'OFF', %w(ON OFF)],
              precharge_voltage: [:voltage, 0],
              settling_time:     [:time, 0],
              tester_state:      [:string, 'CONNECTED', %w(CONNECTED DISCONNECTED UNCHANGED)],
              termination:       [:string, 'OFF', %w(ON OFF)],
              measure_mode:      [:string, 'PPMUpar', %w(PPMUpar PPMUser SPMUser)],
              relay_switch_mode: [:string, 'DEFAULT(BBM)', ['DEFAULT(BBM)', 'BBM', 'MBB', 'PARALLEL']],
              ppmu_clamp_low:    [:voltage, 0],
              ppmu_clamp_high:   [:voltage, 0],
              output:            [:string, 'None', %w(None ReportUI ShowFailOnly)],
              test_name:         [:string, 'passLimit_uA_mV']
            },
            high_z:            {
              pinlist:           [:string, '@'],
              force_voltage:     [:voltage, 2500.mV],
              settling_time:     [:time, 0],
              relay_switch_mode: [:string, 'DEFAULT(BBM)', ['DEFAULT(BBM)', 'BBM', 'MBB', 'PARALLEL']],
              test_name:         [:string, 'passCurrent_uA'],
              output:            [:string, 'None', %w(None ReportUI ShowFailOnly)]
            },
            leakage:           {
              pinlist:                         [:string, '@'],
              measure:                         [:string, 'BOTH', %w(BOTH LOW HIGH)],
              force_voltage_low:               [:voltage, 400.mV],
              force_voltage_high:              [:voltage, 3800.mV],
              spmu_clamp_current_low:          [:current, 0],
              spmu_clamp_current_high:         [:current, 0],
              ppmu_pre_charge:                 [:string, 'ON', %w(ON OFF)],
              precharge_voltage_low:           [:voltage, 0],
              precharge_voltage_high:          [:voltage, 0],
              settling_time_low:               [:time, 0],
              settling_time_high:              [:time, 0],
              pre_function:                    [:string, 'NO', %w(NO ALL ToStopVEC ToStopCYC)],
              control_test_num_off_functional: [:string, 'NO', %w(NO ALL ToStopVEC ToStopCYC)],
              stop_cyc_vec_low:                [:integer, 0],
              stop_cyc_vec_high:               [:integer, 0],
              measure_mode:                    [:string, 'PPMUpar', %w(PPMUpar PPMUser SPMUser)],
              relay_switch_mode:               [:string, 'DEFAULT(BBM)', ['DEFAULT(BBM)', 'BBM', 'MBB', 'PARALLEL']],
              test_name:                       [:string, '(passCurrentLow_uA,passCurrentHigh_uA)'],
              output:                          [:string, 'None', %w(None ReportUI ShowFailOnly)]
            },
            operating_current: {
              dps_pins:    [:string, '@'],
              samples:     [:integer, 4],
              delay_time:  [:time, 0],
              termination: [:string, 'OFF', %w(ON OFF)],
              test_name:   [:string, 'passCurrLimit_uA'],
              output:      [:string, 'None', %w(None ReportUI ShowFailOnly)]
            },
            output_dc:         {
              class_name:              'OutputDC',
              pinlist:                 [:string, ''],
              mode:                    [:string, 'PROGRAMLOAD', %w(PROGRAMLOAD, PPMU SPMU PPMUTERM SPMUTERM)],
              measure_level:           [:string, 'BOTH', %(BOTH LOW HIGH)],
              force_current_low:       [:current, 0],
              force_current_high:      [:current, 0],
              max_pass_low:            [:voltage, 0],
              min_pass_low:            [:voltage, 0],
              max_pass_high:           [:voltage, 0],
              min_pass_high:           [:voltage, 0],
              settling_time_low:       [:time, 0],
              settling_time_high:      [:time, 0],
              spmu_clamp_voltage_low:  [:voltage, 0],
              spmu_clamp_voltage_high: [:voltage, 0],
              vector_range:            [:string, ''],
              test_name:               [:string, '(OutputDC_LowLevel[V],OutputDC_HighLevel[V])'],
              output:                  [:string, 'None', %w(None ReportUI ShowFailOnly)]
            },
            production_iddq:   {
              dps_pins:                       [:string, 'Vee'],
              disconnect_pins:                [:string, ''],
              settling_time:                  [:time, 0],
              stop_mode:                      [:string, 'ToStopVEC', %w(ToStopVEC ToStopCYC)],
              str_stop_vec_cyc_num:           [:string, ''],
              samples:                        [:integer, 16],
              check_functional:               [:string, 'ON', %w(ON OFF)],
              control_test_num_of_functional: [:string, 'OFF', %w(ON OFF)],
              ganged_mode:                    [:string, 'OFF', %w(ON OFF)],
              test_name:                      [:string, 'passCurrLimit_uA'],
              output:                         [:string, 'None', %w(None ReportUI ShowFailOnly)]
            },
            standby_current:   {
              dps_pins:      [:string, '@'],
              samples:       [:integer, 16],
              termination:   [:string, 'OFF', %w(ON OFF)],
              settling_time: [:time, 0],
              test_name:     [:string, 'passCurrLimit_uA'],
              output:        [:string, 'None', %w(None ReportUI ShowFailOnly)]
            }
          }

          def dc_test
            self
          end

          def klass
            'dc_tml.DcTest'
          end
        end
      end
    end
  end
end
