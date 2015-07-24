module OrigenTesters
  module IGXLBasedTester
    class J750
      require 'origen_testers/igxl_based_tester/base/patsubrs'
      class Patsubrs < Base::Patsubrs
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/igxl_based_tester/j750/templates/patsubrs.txt.erb"
      end
    end
  end
end
