module OrigenTesters
  module SmartestBasedTester
    class Base
      class LimitsFile < ATP::Formatter
        include OrigenTesters::Generator

        attr_accessor :ast

        def initialize(ast, options = {})
          @ast = ast
          @used_test_numbers = {}
          lines << '"Suite name","Pins","Test name","Test number","Lsl","Lsl_typ","Usl_typ","Usl","Units","Bin_s_num","Bin_s_name","Bin_h_num","Bin_h_name","Bin_type","Bin_reprobe","Bin_overon","Test_remarks"'
          process(ast)
        end

        def lines
          @lines ||= []
        end

        def subdirectory
          'testtable/limits'
        end

        def on_flow(node)
          @flowname = node.find(:name).value
          process_all(node.children)
        end

        def on_test(node)
          o = {}
          test_obj = node.find(:object).to_a[0]
          o[:suite_name] = test_obj.respond_to?(:name) ? test_obj.name : test_obj
          o[:test_name] = (node.find(:name) || []).to_a[0]
          number = (node.find(:number) || []).to_a[0]
          if number
            if n1 = @used_test_numbers[number]
              if n1.has_source? && node.has_source?
                Origen.log.error "Test number #{number} has been assigned more than once in limits file #{filename} (flow: #{@flowname}):"
                Origen.log.error "  #{n1.source}"
                Origen.log.error "  #{node.source}"
                exit 1
              else
                fail "Test number #{number} cannot be assigned to #{o[:suite_name]} in limits file #{filename} (flow: #{@flowname}), since it has already be used for #{@used_test_numbers[number]}!"
              end
            end
            o[:test_number] = number
            @used_test_numbers[number] = node
          end
          limits = node.find_all(:limit)
          if limits.size > 2
            fail 'More than one pair of limits per test is not supported yet!'
          end
          if limits.empty?
            # Assume it is a functional test in this case
            o[:lsl] = 1
            o[:lsl_typ] = 'GE'
            o[:usl] = 1
            o[:usl_typ] = 'LE'
          else
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
