module Testers
  module IGXLBasedTester
    class J750
      # Include this module in an interface class to make it a J750 interface and to give
      # access to the J750 program generator API
      module Generator
        extend ActiveSupport::Concern

        require_all "#{Origen.root!}/lib/testers/igxl_based_tester/j750"
        require 'testers/igxl_based_tester/base/generator'

        included do
          include Base::Generator
          PLATFORM = J750
        end
      end
    end
  end
end
