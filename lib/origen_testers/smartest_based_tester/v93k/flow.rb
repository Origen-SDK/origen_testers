module OrigenTesters
  module SmartestBasedTester
    class V93K
      require 'origen_testers/smartest_based_tester/base/flow'
      class Flow < Base::Flow
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k/templates/template.tf.erb"

        def flow_header
          h = ['  {']
          if add_flow_enable
            var = filename.sub(/\..*/, '').upcase
            var = generate_flag_name("#{var}_ENABLE")
            if add_flow_enable == :enabled
              flow_control_variables << [var, 1]
            else
              flow_control_variables << [var, 0]
            end
            h << "  if @#{var} == 1 then"
            h << '  {'
            i = '  '
          else
            i = ''
          end
          if set_runtime_variables.size > 0
            h << i + '  {'
            set_runtime_variables.each do |var|
              h << i + "    @#{generate_flag_name(var.to_s)} = -1;"
            end
            h << i + '  }, open,"Init Flow Control Vars", ""'
          end
          h
        end

        def flow_footer
          f = []
          if add_flow_enable
            f << '  }'
            f << '  else'
            f << '  {'
            f << '  }'
          end
          f << ''
          f << "  }, open,\"#{flow_name}\",\"\""
          f
        end
      end
    end
  end
end
