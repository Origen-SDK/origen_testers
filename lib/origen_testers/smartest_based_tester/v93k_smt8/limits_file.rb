module OrigenTesters
  module SmartestBasedTester
    class V93K_SMT8
      require 'origen_testers/smartest_based_tester/base/limits_file'
      class LimitsFile < Base::LimitsFile
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k_smt8/templates/limits.csv.erb"

        def fully_formatted_filename
          "Main.#{@filename}_Tests.csv"
        end
      end
    end
  end
end
