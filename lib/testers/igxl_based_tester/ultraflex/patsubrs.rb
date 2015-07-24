module Testers
  module IGXLBasedTester
    class UltraFLEX
      require 'testers/igxl_based_tester/base/patsubrs'
      class Patsubrs < Base::Patsubrs
        TEMPLATE = "#{RGen.root!}/lib/testers/igxl_based_tester/ultraflex/templates/patsubrs.txt.erb"
      end
    end
  end
end
