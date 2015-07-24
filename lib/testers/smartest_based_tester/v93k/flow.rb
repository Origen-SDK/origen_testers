module Testers
  module SmartestBasedTester
    class V93K
      require 'testers/smartest_based_tester/base/flow'
      class Flow < Base::Flow
        TEMPLATE = "#{RGen.root!}/lib/testers/smartest_based_tester/v93k/templates/template.flow.erb"
      end
    end
  end
end
