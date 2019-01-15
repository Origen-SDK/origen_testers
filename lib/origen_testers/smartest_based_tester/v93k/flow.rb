module OrigenTesters
  module SmartestBasedTester
    class V93K
      require 'origen_testers/smartest_based_tester/base/flow'
      class Flow < Base::Flow
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k/templates/template.tf.erb"

        def flow_header
          h = ['  {']
          if add_flow_enable
            h << "  if @#{flow_enable_var_name} == 1 then"
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
