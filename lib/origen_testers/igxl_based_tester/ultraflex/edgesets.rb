module OrigenTesters
  module IGXLBasedTester
    class UltraFLEX
      require 'origen_testers/igxl_based_tester/base/edgesets'
      class Edgesets < Base::Edgesets
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/igxl_based_tester/ultraflex/templates/edgesets.txt.erb"
      end
    end
  end
end
