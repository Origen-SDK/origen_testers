module OrigenTesters
  module IGXLBasedTester
    class UltraFLEX
      require 'origen_testers/igxl_based_tester/base/global_specs'
      class GlobalSpecs < Base::GlobalSpecs
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/igxl_based_tester/ultraflex/templates/global_specs.txt.erb"
      end
    end
  end
end
