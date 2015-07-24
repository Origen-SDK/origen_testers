module Testers
  module IGXLBasedTester
    class UltraFLEX
      require 'testers/igxl_based_tester/base/patgroups'
      class Patgroups < Base::Patgroups
        TEMPLATE = "#{RGen.root!}/lib/testers/igxl_based_tester/ultraflex/templates/patgroups.txt.erb"
      end
    end
  end
end
