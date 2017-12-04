module OrigenTesters
  module SmartestBasedTester
    class Base
      class LimitsFile < ATP::Formatter
        include OrigenTesters::Generator

        attr_reader :ast, :flow, :test_modes, :flowname

        def initialize(flow, ast, options = {})
          @flow = flow
          @ast = ast
          @flowname = flow.filename.sub(/\..*/, '') # Base off the filename since it will include any prefix
          @used_test_numbers = {}
          @test_modes = Array(options[:test_modes])
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
          process(ast)
        end

        def lines
          @lines ||= []
        end

        def subdirectory
          'testtable/limits'
        end

        def on_test(node)
          o = {}
          o[:suite_name] = extract_test_suite_name(node, o)

          lines << line(extract_line_options(node, o))

          node.find_all(:sub_test).each do |sub_test|
            lines << line(extract_line_options(sub_test, o.dup))
          end

          process_all(node.children)
        end

        private

        def extract_line_options(node, o)
          o[:test_name] = extract_test_name(node, o)
          o[:test_number] = extract_test_number(node, o)
          o[:limits] = extract_limits(node, o)
          if on_fail = node.find(:on_fail)
            if set_result = on_fail.find(:set_result)
              if bin = set_result.find(:bin)
                o[:bin_h_num] = bin.to_a[0] || o[:bin_h_num]
                o[:bin_h_name] = bin.to_a[1] || o[:bin_h_name] || flowname
              end
              if sbin = set_result.find(:softbin)
                o[:bin_s_num] = sbin.to_a[0] || o[:bin_s_num]
                o[:bin_s_name] = sbin.to_a[1] || o[:bin_s_name] || flowname
              end
            end
            if on_fail.find(:delayed)
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

        def extract_test_suite_name(node, o)
          test_obj = node.find(:object).to_a[0]
          test_obj.respond_to?(:name) ? test_obj.name : test_obj if test_obj
        end

        def extract_test_name(node, o)
          (node.find(:name) || []).to_a[0] || extract_test_suite_name(node, o) || o[:suite_name]
        end

        def line(options)
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
          l
        end

        def f(value)
          ",\"#{value}\""
        end
      end
    end
  end
end
