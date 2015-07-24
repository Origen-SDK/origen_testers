module Testers
  module IGXLBasedTester
    class UltraFLEX
      require 'testers/igxl_based_tester/base/flow'
      class Flow < Base::Flow
        TEMPLATE = "#{Origen.root!}/lib/testers/igxl_based_tester/ultraflex/templates/flow.txt.erb"
      end
    end
  end
end
