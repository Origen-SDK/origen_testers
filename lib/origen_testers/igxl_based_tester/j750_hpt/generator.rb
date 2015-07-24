module OrigenTesters
  module IGXLBasedTester
    class J750_HPT
      # Include this module in an interface class to make it a J750 HPT interface and to give
      # access to the J750 HPT program generator API
      module Generator
        extend ActiveSupport::Concern

        require_all "#{Origen.root!}/lib/origen_testers/igxl_based_tester/j750_hpt"
        require 'origen_testers/igxl_based_tester/base/generator'

        included do
          include Base::Generator
          PLATFORM = J750_HPT
        end
      end
    end
  end
end
