module Testers
  module IGXLBasedTester
    class UltraFLEX
      require 'testers/igxl_based_tester/base/test_instances'
      class TestInstances < Base::TestInstances
        TEMPLATE = "#{Origen.root!}/lib/testers/igxl_based_tester/ultraflex/templates/instances.txt.erb"
      end
    end
  end
end
