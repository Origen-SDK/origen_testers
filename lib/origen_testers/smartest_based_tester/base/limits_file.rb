module OrigenTesters
  module SmartestBasedTester
    class Base
      class LimitsFile < ATP::Formatter
        include OrigenTesters::Generator

        attr_accessor :filename, :ast

        def initialize(ast, options = {})
          @ast = ast
          lines << '"Suite name","Pins","Test name","Test number","Lsl","Lsl_typ","Usl_typ","Usl","Units","Bin_s_num","Bin_s_name","Bin_h_num","Bin_h_name","Bin_type","Bin_reprobe","Bin_overon","Test_remarks"'
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
          o[:suite_name] = node.find(:name).to_a[0]
          o[:test_number] = (node.find(:number) || []).to_a[0]
          limits = node.find_all(:limit)
          if limits.size > 2
            fail 'More than one pair of limits per test is not supported yet!'
          end
          limits.each do |limit|
            if limit.to_a[1] =~ /^G/i
              o[:lsl] = limit.to_a[0]
              o[:lsl_typ] = limit.to_a[1]
            else
              o[:usl] = limit.to_a[0]
              o[:usl_typ] = limit.to_a[1]
            end
            o[:units] = limit.to_a[2]
          end
          if on_fail = node.find(:on_fail)
            if set_result = on_fail.find(:set_result)
              if bin = set_result.find(:bin)
                o[:bin_h_num] = bin.to_a[0]
              end
              if sbin = set_result.find(:softbin)
                o[:bin_s_num] = sbin.to_a[0]
              end
            end
          end
          lines << line(o)
        end

        private

        def line(options)
          # "Suite name"
          l = "\"#{options[:suite_name]}\""
          # "Pins"
          l << f(options[:pins])
          # "Test name"
          l << f(options[:test_name])
          # "Test number"
          l << f(options[:test_number])
          # "Lsl"
          l << f(options[:lsl])
          # "Lsl_typ"
          l << f(options[:lsl_typ])
          # "Usl_typ"
          l << f(options[:usl_typ])
          # "Usl"
          l << f(options[:usl])
          # "Units"
          l << f(options[:units])
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
