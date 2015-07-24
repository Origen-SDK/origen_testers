module Testers
  module SmartestBasedTester
    class V93K
      require 'testers/smartest_based_tester/base/pattern_master'
      class PatternMaster < Base::PatternMaster
        TEMPLATE = "#{RGen.root!}/lib/testers/smartest_based_tester/v93k/templates/template.pmfl.erb"
      end
    end
  end
end
