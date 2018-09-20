require 'rodf'
module OrigenTesters
  module SmartestBasedTester
    class V93K_SMT8
      # Responsible for creating a limits workbook for each program generation run
      # Each limits file will generate a sheet within this workbook
      class LimitsWorkbook
        include OrigenTesters::Generator

        def initialize(options = {})
          @softbins = {}
          @bins = {}
        end

        def add_softbin(number, options = {})
          options = {
            name:     nil,
            bin:      nil,
            result:   'FAIL',
            color:    'RED',
            priority: 2
          }.merge(options)
          attrs = @softbins[number] || {}

          attrs[:name] = options[:name] if options[:name]
          attrs[:bin] = options[:bin] if options[:bin]
          if !attrs[:result] || (options[:result] && options[:result] != 'FAIL')
            attrs[:result] = options[:result]
          end
          if !attrs[:color] || (options[:color] && options[:color] != 'RED')
            attrs[:color] = options[:color]
          end
          if !attrs[:priority] || (options[:priority] && options[:priority] != 2)
            attrs[:priority] = options[:priority]
          end

          @softbins[number] = attrs
        end

        def add_bin(number, options = {})
          options = {
            name:   nil,
            result: 'FAIL'
          }.merge(options)

          attrs = @bins[number] || {}

          attrs[:name] = options[:name] if options[:name]
          if !attrs[:result] || (options[:result] && options[:result] != 'FAIL')
            attrs[:result] = options[:result]
          end

          @bins[number] = attrs
        end

        def fully_formatted_filename
          'limits.ods'
        end

        def subdirectory
          "#{tester.package_namespace}/common"
        end

        def write_to_file(options = {})
          Origen.log.info "Writing... #{output_file}"
          softbins = @softbins
          bins = @bins
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
            # Write out the softbin table
            table 'Software_Bins' do
              row do
                cell 'Software Bin'
                cell 'Software Bin Name'
                cell 'Hardware Bin'
                cell 'Result'
                cell 'Color'
                cell 'Priority'
              end
              softbins.each do |sbin, attrs|
                row do
                  cell sbin
                  cell attrs[:name]
                  cell attrs[:bin]
                  cell attrs[:result]
                  cell attrs[:color]
                  cell attrs[:priority]
                end
              end
            end

            # Write out the bin table
            table 'Hardware_Bins' do
              row do
                cell 'Hardware Bin'
                cell 'Hardware Bin Name'
                cell 'Result'
              end
              bins.each do |bin, attrs|
                row do
                  cell bin
                  cell attrs[:name]
                  cell attrs[:result]
                end
              end
            end
          end
        end
      end
    end
  end
end
