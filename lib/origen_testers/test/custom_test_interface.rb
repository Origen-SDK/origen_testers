module OrigenTesters
  module Test
    class CustomTestInterface
      include OrigenTesters::ProgramGenerators

      def initialize(options = {})
        add_custom_til if tester.try(:igxl_based?)
        add_custom_tml if tester.v93k?
      end

      def custom(name, options = {})
        name = "custom_#{name}".to_sym
        if tester.try(:igxl_based?)
          ti = test_instances.mylib.test_a(name)
          ti.my_arg0 = 'arg0_set'
          ti.my_arg2_alias = 'curr'
          ti.set_my_arg4('arg4_set_from_method')

        elsif tester.v93k?
          ti = test_methods.my_tml.test_a
          ti.my_arg0 = 'arg0_set'
          ti.my_arg2_alias = 'CURR'
          ti.set_my_arg4('arg4_set_from_method')

        end
      end

      def custom_b(name, options = {})
        name = "custom_b_#{name}".to_sym
        if tester.v93k?
          ti = test_methods.my_tml.test_b
          ti.my_arg0 = 'arg0_set'
        end
      end

      def custom_c(name, options = {})
        name = "custom_c_#{name}".to_sym
        if tester.v93k?
          ti = test_methods.my_tml.test_c
          ti.my_arg0 = 'arg0_set'
          if options[:my_arg1]
            ti.my_arg0 = 'arg1_should_render'
            ti.my_arg1 = options[:my_arg1]
          else
            ti.my_arg0 = 'arg1_should_not_render'
          end
        end
      end

      def custom_d(name, options = {})
        name = "custom_d_#{name}".to_sym
        if tester.v93k?
          ti = test_methods.my_tml.test_d
        end
      end

      def custom_hash(name, options = {})
        name = "custom_hash_#{name}".to_sym
        if tester.v93k? && tester.smt8?
          ti = test_methods.my_tml.test_hash
          ti.my_arg_hash = {
            my_param_name: {
              my_arg2: 1
            }
          }
        end
      end

      private

      def add_custom_tml
        add_tml :my_tml,
                test_a:    {
                  # Parameters can be defined with an underscored symbol as the name, this can be used
                  # if the C++ implementation follows the standard V93K convention of calling the attribute
                  # the camel cased version, starting with a lower-cased letter, i.e. 'testerState' in this
                  # first example.
                  # The attribute definition has two required parameters, the type and the default value.
                  # The type can be :string, :current, :voltage, :time, :frequency, or :integer
                  # An optional 3rd parameter can be supplied to give an array of allowed values. If supplied,
                  # Origen will raise an error upon an attempt to set it to an unlisted value.
                  tester_state: [:string, 'CONNECTED', %w(CONNECTED UNCHANGED)],
                  test_name: [:string, 'Functional'],
                  my_arg0: [:string, ''],
                  my_arg1: [:string, 'a_default_value'],
                  my_arg2: [:string, 'VOLT', %w(VOLT CURR)],
                  my_arg3: [:string, ''],
                  my_arg4: [:string, ''],
                  # In cases where the C++ library has deviated from standard attribute naming conventions
                  # (camel-cased with lower cased first character), the absolute attribute name can be given
                  # as a string.
                  # The Ruby/Origen accessor for these will be the underscored version, with '.' characters
                  # converted to underscores, e.g. tm.bad_practice, tm.really_bad_practice, etc.
                  'BadPractice' => [:string, 'NO', %w(NO YES)],
                  'Really.BadPractice' => [:string, ''],
                  # Attribute aliases can be defined like this:
                  aliases: {
                    my_arg2_alias: :my_arg2
                  },
                  # Define any methods you want the test method to have
                  methods: {
                    # An optional finalize function can be supplied to do any final test instance configuration, this
                    # function will be called immediately before the test method is finally rendered. The test method
                    # object itself will be passed in as an argument.
                    finalize:    lambda  do |tm|
                      tm.my_arg3 = 'arg3_set_from_finalize'
                    end,
                    # Example of a custom method.
                    # In all cases the test method object will be passed in as the first argument.
                    set_my_arg4: lambda  do |tm, val|
                      tm.my_arg4 = val
                    end
                  }
                },
                test_b:    {
                  render_limits_in_tf: false,
                  my_arg0:             [:string, ''],
                  my_arg1:             [:string, 'b_default_value']
                },
                test_c:    {
                  tester_state: [:string, 'CONNECTED', %w(CONNECTED UNCHANGED)],
                  test_name:    [:string, 'Functional'],
                  my_arg0:      [:string, ''],
                  my_arg1:      [:string, 'DELETE_ME'],
                  my_arg2:      [:string, 'VOLT', %w(VOLT CURR)],

                  # Define any methods you want the test method to have
                  methods:      {
                    # An optional finalize function can be supplied to do any final test instance configuration, this
                    # function will be called immediately before the test method is finally rendered. The test method
                    # object itself will be passed in as an argument.
                    finalize:    lambda  do |tm|
                      if tm.my_arg1 == 'DELETE_ME'
                        tm.remove_parameter(:my_arg1)
                      end
                    end
                  }
                },
                test_d:    {
                  tester_state:         [:string, 'CONNECTED', %w(CONNECTED UNCHANGED)],
                  test_name:            [:string, 'Functional'],
                  current_arg:          [:current, 1],
                  current_no_default:   [:current, ''],
                  voltage_arg:          [:voltage, 1.2],
                  voltage_no_default:   [:voltage, ''],
                  time_arg:             [:time, 10],
                  time_no_default:      [:time, ''],
                  frequency_arg:        [:frequency, 1_000_000],
                  frequency_no_default: [:frequency, ''],
                  integer_arg:          [:integer, 5.22],
                  integer_no_default:   [:integer, ''],
                  double_arg:           [:double, '5.22'],
                  double_no_default:    [:double, ''],
                  boolean_arg:          [:boolean, true],
                  boolean_no_default:   [:boolean, '']
                },
                test_hash: {
                  # Parameters can be defined with an underscored symbol as the name, this can be used
                  # if the C++ implementation follows the standard V93K convention of calling the attribute
                  # the camel cased version, starting with a lower-cased letter, i.e. 'testerState' in this
                  # first example.
                  # The attribute definition has two required parameters, the type and the default value.
                  # The type can be :string, :current, :voltage, :time, :frequency, or :integer
                  # An optional 3rd parameter can be supplied to give an array of allowed values. If supplied,
                  # Origen will raise an error upon an attempt to set it to an unlisted value.
                  tester_state:   [:string, 'CONNECTED', %w(CONNECTED UNCHANGED)],
                  test_name:      [:string, 'Functional'],
                  my_list_string: [:list_strings, %w(E1 E2)],
                  my_list_class:  [:list_classes, %w(E1 E2)],
                  my_arg_hash:    [{
                    my_arg0: [:string, ''],
                    my_arg1: [:string, 'a_default_value'],
                    my_arg2: [:integer, 0],
                    my_arg2: [:list_strings, %w(E1 E2)],
                    my_arg3: [:list_classes, %w(E1 E2)]
                  }]
                  # Define any methods you want the test method to have
                }
      end

      def add_custom_til
        add_til :mylib,
                test_a: {
                  # Basic arg
                  my_arg0: :arg0,
                  # Basic arg with default value
                  my_arg1: [:arg1, 'a_default_value'],
                  # Basic arg with default value and possible values
                  my_arg2: [:arg2, 'volt', %w(volt curr)],
                  my_arg3: :arg3,
                  my_arg4: :arg4,
                  # Attribute aliases can be defined like this:
                  aliases: {
                    my_arg_alias:  :my_arg,
                    my_arg1_alias: :my_arg1,
                    my_arg2_alias: :my_arg2
                  },
                  # Define any methods you want the test method to have
                  methods: {
                    # An optional finalize function can be supplied to do any final test instance configuration, this
                    # function will be called immediately before the test instance is finally rendered. The test instance
                    # object itself will be passed in as an argument.
                    finalize:    lambda  do |ti|
                      ti.my_arg3 = 'arg3_set_from_finalize'
                    end,
                    # Example of a custom method.
                    # In all cases the test method object will be passed in as the first argument.
                    set_my_arg4: lambda  do |ti, val|
                      ti.my_arg4 = val
                    end
                  }
                }
      end
    end
  end
end
