module Testers
  module IGXLBasedTester
    class J750
      require 'testers/igxl_based_tester/base/flow'
      class Flow < Base::Flow
        TEMPLATE = "#{RGen.root!}/lib/testers/igxl_based_tester/j750/templates/flow.txt.erb"
      end
    end
  end
end
