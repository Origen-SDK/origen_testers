module OrigenTesters
  module IGXLBasedTester
    class UltraFLEX
      require 'origen_testers/igxl_based_tester/base/patgroups'
      class Patgroups < Base::Patgroups
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/igxl_based_tester/ultraflex/templates/patgroups.txt.erb"
      end
    end
  end
end
