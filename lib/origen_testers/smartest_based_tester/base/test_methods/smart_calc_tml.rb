module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestMethods
        class SmartCalcTml < BaseTml
          TEST_METHODS = {
            synchronize: {
              class_name: 'SMC__SYNCHRONIZE'
            },
            cleanup:     {
              class_name: 'SMC__CLEANUP',
              disconnect: [:boolean, false]
            }
          }

          def klass
            'smartCalc'
          end
        end
      end
    end
  end
end
