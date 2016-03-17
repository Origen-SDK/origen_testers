module OrigenTesters
  module IGXLBasedTester
    class UltraFLEX
      require 'origen_testers/igxl_based_tester/base/ac_specsets'
      class ACSpecsets < Base::ACSpecsets
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/igxl_based_tester/ultraflex/templates/ac_specsets.txt.erb"
      end
    end
  end
end
