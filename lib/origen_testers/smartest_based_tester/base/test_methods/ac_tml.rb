module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestMethods
        class AcTml < BaseTml
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
            }
          }

          def ac_test
            self
          end

          def klass
            'ac_tml.AcTest'
          end
        end
      end
    end
  end
end
