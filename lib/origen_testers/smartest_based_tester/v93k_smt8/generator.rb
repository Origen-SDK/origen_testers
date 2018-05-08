module OrigenTesters
  module SmartestBasedTester
    class V93K_SMT8
      # Include this module in an interface class to make it a V93K interface and to give
      # access to the V93K SMT8 program generator API
      module Generator
        extend ActiveSupport::Concern

        require_all "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k_smt8"
        require 'origen_testers/smartest_based_tester/base/generator'

        included do
          include Base::Generator
          PLATFORM = V93K_SMT8
        end

        def limits_workbook
          @@limits_workbook ||= begin
            m = LimitsWorkbook.new(manually_register: true)
            m.filename = 'limits.ods'
            m
          end
        end
      end
    end
  end
end
