module OrigenTesters
  module Test
    class CustomTestInterface
      include OrigenTesters::ProgramGenerators

      def initialize(options = {})
        add_custom_igxl_tests if tester.try(:igxl_based?)
      end

      def custom(name, options = {})
        if name == :test1
          if tester.j750?
            ti = test_instances.mylib.test_a(:test)
            ti.my_arg0 = 'arg0_set'
            ti.my_arg2_alias = 'curr'
            ti.set_my_arg4('arg4_set')
          end
        end
      end

      private

      def add_custom_igxl_tests
        add_til :mylib,
                test_a: {
                  # Basic arg
                  my_arg:  :arg0,
                  # Basic arg with default value
                  my_arg1: [:arg1, 10],
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
                    # function will be called immediately before the test method is finally rendered. The test instance
                    # object itself will be passed in as an argument.
                    finalize:    lambda  do |ti|
                      ti.my_arg3 = 'arg3_set'
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
