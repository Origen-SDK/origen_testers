module OrigenTesters
  module IGXLBasedTester
    class UltraFLEX
      require 'origen_testers/igxl_based_tester/base/timesets_basic'
      class TimesetsBasic < Base::TimesetsBasic
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/igxl_based_tester/ultraflex/templates/timesets_basic.txt.erb"
      end
    end
  end
end
