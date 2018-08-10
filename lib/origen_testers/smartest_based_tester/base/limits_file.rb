require 'origen_testers/smartest_based_tester/base/processors/extract_bin_names'
module OrigenTesters
  module SmartestBasedTester
    class Base
      class LimitsFile < ATP::Formatter
        include OrigenTesters::Generator

        attr_reader :flow, :test_modes, :flowname, :bin_names

        def initialize(flow, options = {})
          @flow = flow
          @flowname = flow.filename.sub(/\..*/, '') # Base off the filename since it will include any prefix
          @used_test_numbers = {}
          @test_modes = Array(options[:test_modes])
          @empty = true
          @smt8 = tester.smt8?
        end

        def header
          if smt8?
            @test_path = []
            l = 'Test Suite,Test,Test Number,Test Text'
            if test_modes.empty?
              l += ',Low Limit,High Limit'
            else
              l += ',Low Limit'
              (test_modes.size - 1).times { l += ',' }
              l += ',High Limit'
              (test_modes.size - 1).times { l += ',' }
            end
            l += ',Unit,Soft Bin'
            lines << l

            l = ',,,'
            if test_modes.empty?
              l += ',default,default'
            else
              test_modes.each { |mode| l += ",#{mode}" }
              test_modes.each { |mode| l += ",#{mode}" }
            end
            lines << l

          else
            l = '"Suite name","Pins","Test name","Test number"'
            if test_modes.empty?
              l += ',"Lsl","Lsl_typ","Usl_typ","Usl","Units","Bin_s_num","Bin_s_name","Bin_h_num","Bin_h_name","Bin_type","Bin_reprobe","Bin_overon","Test_remarks"'
              lines << l
            else
              l += (',"Lsl","Lsl_typ","Usl_typ","Usl","Units"' * test_modes.size) + ',"Bin_s_num","Bin_s_name","Bin_h_num","Bin_h_name","Bin_type","Bin_reprobe","Bin_overon","Test_remarks"'
              lines << l
              l = '"Test mode",,,'
              test_modes.each do |mode|
                l += ",\"#{mode}\",\"#{mode}\",\"#{mode}\",\"#{mode}\",\"#{mode}\""
              end
              l += ',,,,,,,,'
              lines << l
            end
          end
        end

        def test_modes=(modes)
          @test_modes = Array(modes)
        end

        def generate(ast)
          @bin_names = Processors::ExtractBinNames.new.run(ast)
          header
          process(ast)
        end

        def lines
          @lines ||= []
        end

        def subdirectory
          if tester.smt7?
            'testtable/limits'
          else
            "#{tester.package_namespace}/limits"
          end
        end

        def on_test(node)
          o = {}
          o[:suite_name] = extract_test_suite_name(node)

          lines << line(extract_line_options(node, o))

          node.find_all(:sub_test).each do |sub_test|
            lines << line(extract_line_options(sub_test, o.dup))
          end

          process_all(node.children)
        end

        def on_sub_flow(node)
          @test_path << Pathname.new(node.find(:path).value).basename('.*').to_s
          process_all(node.children)
          @test_path.pop
        end

        # Returns true if the AST provided when initializing this limits table generator did not
        # contain any tests, i.e. the resultant limits file is empty
        def empty?
          @empty
        end

        private

        def smt8?
          @smt8
        end

        def extract_line_options(node, o)
          o[:test_name] = extract_test_name(node, o)
          o[:test_number] = extract_test_number(node, o)
          o[:limits] = extract_limits(node, o)
          if on_fail = node.find(:on_fail)
            if set_result = on_fail.find(:set_result)
              if bin = set_result.find(:bin)
                o[:bin_h_num] = bin.to_a[0] || o[:bin_h_num]
                o[:bin_h_name] = bin_names[:hard][bin.to_a[0]][:name]
              end
              if sbin = set_result.find(:softbin)
                o[:bin_s_num] = sbin.to_a[0] || o[:bin_s_num]
                o[:bin_s_name] = bin_names[:soft][sbin.to_a[0]][:name]
              end
            end
            delayed = on_fail.find(:delayed)
            if delayed && !delayed.to_a[0]
              o[:bin_overon] = 'no'
            elsif (delayed && delayed.to_a[0]) || tester.delayed_binning
              o[:bin_overon] = 'on'
            else
              o[:bin_overon] = 'no'
            end
          end
          o
        end

        def extract_limits(node, o)
          modes = test_modes
          lims = {}
          (modes + [nil]).each do |mode|
            lims[mode] = {}
            if node.find(:nolimits)
              lims[mode][:lsl] = nil
              lims[mode][:lsl_typ] = 'NA'
              lims[mode][:usl] = nil
              lims[mode][:usl_typ] = 'NA'
            else
              limits = node.find_all(:limit)
              if limits.empty?
                # Assume it is a functional test in this case
                lims[mode][:lsl] = 0
                lims[mode][:lsl_typ] = 'GE'
                lims[mode][:usl] = 0
                lims[mode][:usl_typ] = 'LE'
              else
                limits.find_all { |l| l.to_a[3].to_s == mode.to_s }.each do |limit|
                  limit = limit.to_a
                  if limit[1] =~ /^G/i
                    lims[mode][:lsl] = limit[0]
                    lims[mode][:lsl_typ] = limit[0] ? limit[1].to_s.upcase : nil
                    lims[mode][:lsl_typ] = 'GE' if lims[mode][:lsl_typ] == 'GTE'
                  else
                    lims[mode][:usl] = limit[0]
                    lims[mode][:usl_typ] = limit[0] ? limit[1].to_s.upcase : nil
                    lims[mode][:usl_typ] = 'LE' if lims[mode][:usl_typ] == 'LTE'
                  end
                  lims[mode][:units] = limit[2]
                end
              end
            end
          end
          lims
        end

        def extract_test_number(node, o)
          number = (node.find(:number) || []).to_a[0]
          if number
            if n1 = @used_test_numbers[number]
              if n1.has_source? && node.has_source?
                Origen.log.error "Test number #{number} has been assigned more than once in limits file #{filename} (flow: #{flowname}):"
                Origen.log.error "  #{n1.source}"
                Origen.log.error "  #{node.source}"
                exit 1
              else
                fail "Test number #{number} cannot be assigned to #{o[:suite_name]} in limits file #{filename} (flow: #{flowname}), since it has already be used for #{@used_test_numbers[number]}!"
              end
            end
            @used_test_numbers[number] = node
            number
          end
        end

        def extract_test_suite_name(node)
          test_obj = node.find(:object).to_a[0]
          if test_obj.is_a?(Hash)
            name = test_obj['Test']
          else
            name = test_obj.respond_to?(:name) ? test_obj.name : test_obj if test_obj
          end
          name
        end

        def extract_test_name(node, o)
          test_obj = node.find(:object).to_a[0]
          if smt8?
            if test_obj.is_a?(Hash) && test_obj['Sub Test Name']
              name = test_obj['Sub Test Name']
            else
              name = test_obj.try(:sub_test_name)
            end
          end
          unless name
            if test_obj.is_a?(Hash) && test_obj['Test Name']
              name = test_obj['Test Name']
            elsif test_obj.is_a?(String)
              name = test_obj
            else
              name = (node.find(:name) || []).to_a[0] || extract_test_suite_name(node, o) || o[:suite_name]
            end
          end
          name
        end

        def line(options)
          @empty = false

          if smt8?
            # "Test Suite"
            if @test_path.empty?
              l = "#{options[:suite_name]}"
            else
              l = "#{@test_path.join('.')}.#{options[:suite_name]}"
            end
            # "Test"
            l << f(options[:test_name])
            # "Test Number"
            l << f(options[:test_number])
            # "Test Text"
            l << f(options[:bin_s_name] || options[:bin_h_name])
            if test_modes.empty?
              # "Low Limit"
              l << f((options[:limits][nil] || {})[:lsl])
              # "High Limit"
              l << f((options[:limits][nil] || {})[:usl])
            else
              test_modes.each do |mode|
                # "Low Limit"
                l << f((options[:limits][mode] || options[:limits][nil] || {})[:lsl] || 'na')
              end
              test_modes.each do |mode|
                # "High Limit"
                l << f((options[:limits][mode] || options[:limits][nil] || {})[:usl] || 'na')
              end
            end
            # "Unit"
            l << f((options[:limits][nil] || {})[:units])
            # "Soft Bin"
            l << f(options[:bin_s_num])

          else
            # "Suite name"
            l = "\"#{options[:suite_name]}\""
            # "Pins"
            l << f(options[:pins])
            # "Test name"
            l << f(options[:test_name])
            # "Test number"
            l << f(options[:test_number])
            if test_modes.empty?
              # "Lsl"
              l << f((options[:limits][nil] || {})[:lsl])
              # "Lsl_typ"
              l << f((options[:limits][nil] || {})[:lsl_typ])
              # "Usl_typ"
              l << f((options[:limits][nil] || {})[:usl_typ])
              # "Usl"
              l << f((options[:limits][nil] || {})[:usl])
              # "Units"
              l << f((options[:limits][nil] || {})[:units])
            else
              test_modes.each do |mode|
                # "Lsl"
                l << f((options[:limits][mode] || options[:limits][nil] || {})[:lsl])
                # "Lsl_typ"
                l << f((options[:limits][mode] || options[:limits][nil] || {})[:lsl_typ])
                # "Usl_typ"
                l << f((options[:limits][mode] || options[:limits][nil] || {})[:usl_typ])
                # "Usl"
                l << f((options[:limits][mode] || options[:limits][nil] || {})[:usl])
                # "Units"
                l << f((options[:limits][mode] || options[:limits][nil] || {})[:units])
              end
            end
            # "Bin_s_num"
            l << f(options[:bin_s_num])
            # "Bin_s_name"
            l << f(options[:bin_s_name])
            # "Bin_h_num"
            l << f(options[:bin_h_num])
            # "Bin_h_name"
            l << f(options[:bin_h_name])
            # "Bin_type"
            l << f(options[:bin_type])
            # "Bin_reprobe"
            l << f(options[:bin_reprobe])
            # "Bin_overon"
            l << f(options[:bin_overon])
            # "Test_remarks"
            l << f(options[:test_remarks])
          end
          l
        end

        def f(value)
          if smt8?
            ",#{value}"
          else
            ",\"#{value}\""
          end
        end
      end
    end
  end
end
