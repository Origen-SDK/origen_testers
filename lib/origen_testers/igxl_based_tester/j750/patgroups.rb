module Testers
  module IGXLBasedTester
    class J750
      require 'testers/igxl_based_tester/base/patgroups'
      class Patgroups < Base::Patgroups
        TEMPLATE = "#{Origen.root!}/lib/testers/igxl_based_tester/j750/templates/patgroups.txt.erb"
      end
    end
  end
end
