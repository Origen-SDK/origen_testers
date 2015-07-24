module OrigenTesters
  module IGXLBasedTester
    class J750
      require 'origen_testers/igxl_based_tester/base/patsets'
      class Patsets < Base::Patsets
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/igxl_based_tester/j750/templates/patsets.txt.erb"
      end
    end
  end
end
