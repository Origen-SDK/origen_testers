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
          spreadsheet = RODF::Spreadsheet.new
          Origen.interface.flow_sheets.each do |name, flow|
            if tester.create_limits_file
              if flow.limits_file
                limits_name = flow.limits_file.filename.sub('.csv', '')
                table = spreadsheet.table limits_name
                flow.limits_file.output_file.readlines.each_with_index do |line, i|
                  # Need to fix the first row, SMT8 won't allow the Low/High limits cells not to be merged
                  if i == 0
                    row = table.row
                    x = nil
                    line.chomp.split(',').each do |word|
                      if word == 'Low Limit'
                        x = 0
                      elsif word == 'High Limit'
                        row.cell 'Low Limit', span: x + 1
                        x = 0
                      elsif word == 'Unit'
                        row.cell 'High Limit', span: x + 1
                        row.cell word
                        x = nil
                      elsif x
                        x += 1
                      else
                        row.cell word
                      end
                    end
                  else
                    row = table.row
                    line.chomp.split(',').each do |word|
                      row.cell word
                    end
                  end
                end
              end
            end
          end
          if tester.separate_bins_file
            bins_file = output_file.sub('.ods', '_bins.ods')
            Origen.log.info "Writing... #{bins_file}"
            bins_ss = RODF::Spreadsheet.new
            add_bin_sheets(bins_ss)
            bins_ss.write_to(bins_file)
          else
            add_bin_sheets(spreadsheet)
          end
          spreadsheet.write_to(output_file)
        end

        def add_bin_sheets(spreadsheet)
          table = spreadsheet.table 'Software_Bins'
          row = table.row
          row.cell 'Software Bin'
          row.cell 'Software Bin Name'
          row.cell 'Hardware Bin'
          row.cell 'Result'
          row.cell 'Color'
          row.cell 'Priority'
          @softbins.each do |sbin, attrs|
            row = table.row
            row.cell sbin
            row.cell attrs[:name]
            row.cell attrs[:bin]
            row.cell attrs[:result]
            row.cell attrs[:color]
            row.cell attrs[:priority]
          end

          # Write out the bin table
          table = spreadsheet.table 'Hardware_Bins'
          row = table.row
          row.cell 'Hardware Bin'
          row.cell 'Hardware Bin Name'
          row.cell 'Result'
          @bins.each do |bin, attrs|
            row = table.row
            row.cell bin
            row.cell attrs[:name]
            row.cell attrs[:result]
          end
        end
      end
    end
  end
end
