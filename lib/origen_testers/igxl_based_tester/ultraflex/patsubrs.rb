module Testers
  module IGXLBasedTester
    class UltraFLEX
      require 'testers/igxl_based_tester/base/patsubrs'
      class Patsubrs < Base::Patsubrs
        TEMPLATE = "#{Origen.root!}/lib/testers/igxl_based_tester/ultraflex/templates/patsubrs.txt.erb"
      end
    end
  end
end
