module OrigenTesters
  module SmartestBasedTester
    class V93K_SMT8
      # Responsible for creating a limits workbook for each program generation run
      # Each limits file will generate a sheet within this workbook
      class LimitsWorkbook
        include OrigenTesters::Generator

        def initialize(options = {})
        end

        def subdirectory
          'common'
        end

        def write_to_file(options = {})
          puts "WRITING LIMITSSSSSSSSSSSSSSSSSSSSSSSSSS - #{object_id}"
        end
      end
    end
  end
end
