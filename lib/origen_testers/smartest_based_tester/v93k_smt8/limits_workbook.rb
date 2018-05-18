require 'rodf'
module OrigenTesters
  module SmartestBasedTester
    class V93K_SMT8
      # Responsible for creating a limits workbook for each program generation run
      # Each limits file will generate a sheet within this workbook
      class LimitsWorkbook
        include OrigenTesters::Generator

        def initialize(options = {})
        end

        def fully_formatted_filename
          'limits.ods'
        end

        def subdirectory
          "#{tester.package_namespace}/common"
        end

        def write_to_file(options = {})
          Origen.log.info "Writing... #{output_file}"
          RODF::Spreadsheet.file(output_file) do
            Origen.interface.flow_sheets.each do |name, flow|
              if flow.limits_file
                limits_name = flow.limits_file.filename.sub('.csv', '')
                table limits_name do
                  flow.limits_file.output_file.readlines.each_with_index do |line, i|
                    # Need to fix the first row, SMT8 won't allow the Low/High limits cells not to be merged
                    if i == 0
                      row do
                        x = nil
                        line.chomp.split(',').each do |word|
                          if word == 'Low Limit'
                            x = 0
                          elsif word == 'High Limit'
                            cell 'Low Limit', span: x + 1
                            x = 0
                          elsif word == 'Unit'
                            cell 'High Limit', span: x + 1
                            cell word
                            x = nil
                          elsif x
                            x += 1
                          else
                            cell word
                          end
                        end
                      end
                    else
                      row do
                        line.chomp.split(',').each do |word|
                          cell word
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
