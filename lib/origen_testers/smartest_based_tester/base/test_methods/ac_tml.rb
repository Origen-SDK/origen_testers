module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestMethods
        class AcTmlNative < BaseTml
          TEST_METHODS = {
            frequency_by_digital_capture: {
              class_name:           'Frequency_byDigitalCapture',
              vector_variable_name: [:string, ''],
              algorithm:            [:string, 'FFT', %w(FFT LinearFit)],
              sample_period:        [:time, 0],
              target_frequency:     [:frequency, 0],
              output:               [:string, 'None', %w(None ReportUI ShowFailOnly)],
              test_name:            [:string, 'passFrequency_MHz']
            },
            functional_test:              {
              test_name: [:string, 'Functional'],
              output:    [:string, 'None', %w(None ReportUI ShowFailOnly)]
            },
            spec_search:                  {
              max:            [:string, nil],
              method:         [:string, nil],
              min:            [:string, nil],
              output:         [:string, 'None', %w(None ReportUI ShowFailOnly)],
              resolution:     [:string, ''],
              result_pinlist: [:string, ''],
              setup_pinlist:  [:string, ''],
              spec:           [:string, nil],
              step:           [:string, nil],
              test_name:      [:string, 'SpecSearch_Test']
            }
          }

          def ac_test
            self
          end

          def klass
            'ac_tml_native.AcTest'
          end
        end
      end
    end
  end
end
