module OrigenTesters
  module IGXLBasedTester
    class UltraFLEX
      require 'origen_testers/igxl_based_tester/base/timesets'
      class Timesets < Base::Timesets
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/igxl_based_tester/ultraflex/templates/timesets.txt.erb"
      end
    end
  end
end
