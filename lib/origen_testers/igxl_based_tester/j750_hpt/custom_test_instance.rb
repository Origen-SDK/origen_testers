module OrigenTesters
  module IGXLBasedTester
    class J750_HPT
      require 'origen_testers/igxl_based_tester/base/custom_test_instance'
      class CustomTestInstance < Base::CustomTestInstance
        # Attributes for each test instance line, first few are named directly
        TEST_INSTANCE_ATTRS = %w(
          test_name proc_type proc_name proc_called_as dc_category
          dc_selector ac_category ac_selector
          time_sets edge_sets pin_levels overlay
        )

        # Attributes for additional test instance arguments beyond those described above
        TEST_INSTANCE_EXTRA_ARGS = 80

        TEST_INSTANCE_DEFAULTS = {
          proc_type:      'Other',
          proc_called_as: 'VB DLL'
        }

        TEST_INSTANCE_ALIASES = {
          name:     :test_name,
          time_set: :time_sets,
          timeset:  :time_sets,
          timesets: :time_sets
        }

        define
      end
    end
  end
end
