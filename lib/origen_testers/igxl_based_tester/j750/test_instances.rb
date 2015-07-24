module Testers
  module IGXLBasedTester
    class J750
      require 'testers/igxl_based_tester/base/test_instances'
      class TestInstances < Base::TestInstances
        TEMPLATE = "#{Origen.root!}/lib/testers/igxl_based_tester/j750/templates/instances.txt.erb"
      end
    end
  end
end
