module OrigenTesters
  module IGXLBasedTester
    class UltraFLEX
      require 'origen_testers/igxl_based_tester/base/patsubrs'
      class Patsubrs < Base::Patsubrs
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/igxl_based_tester/ultraflex/templates/patsubrs.txt.erb"
      end
    end
  end
end
