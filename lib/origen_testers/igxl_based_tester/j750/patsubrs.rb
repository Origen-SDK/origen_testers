module Testers
  module IGXLBasedTester
    class J750
      require 'testers/igxl_based_tester/base/patsubrs'
      class Patsubrs < Base::Patsubrs
        TEMPLATE = "#{Origen.root!}/lib/testers/igxl_based_tester/j750/templates/patsubrs.txt.erb"
      end
    end
  end
end
