module Testers
  module IGXLBasedTester
    class UltraFLEX
      require 'testers/igxl_based_tester/base/flow_line'
      class FlowLine < Base::FlowLine
        # Attributes for each flow line, these must be declared in the order they are to be output
        TESTER_FLOWLINE_ATTRS = %w(label enable job part env opcode parameter tname tnum lolim hilim scale units format
                                   bin_pass bin_fail sort_pass sort_fail result flag_pass flag_fail state
                                   group_specifier group_sense group_condition group_name
                                   device_sense device_condition device_name
                                   debug_assume debug_sites comment
                                )

        # Generate the instance method definitions based on the above
        define
      end
    end
  end
end
