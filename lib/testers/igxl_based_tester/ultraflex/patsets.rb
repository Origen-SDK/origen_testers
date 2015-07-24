module Testers
  module IGXLBasedTester
    class UltraFLEX
      require 'testers/igxl_based_tester/base/patsets'
      class Patsets < Base::Patsets
        TEMPLATE = "#{RGen.root!}/lib/testers/igxl_based_tester/ultraflex/templates/patsets.txt.erb"
      end
    end
  end
end
