module OrigenTesters
  module SmartestBasedTester
    class V93K_SMT8
      require 'origen_testers/smartest_based_tester/base/flow'
      class Flow < Base::Flow
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k_smt8/templates/template.flow.erb"

        def on_sub_flow(node)
          # In the returned vars :this_flow means this sub_flow, :sub_flows refers to any further
          # sub_flows that are nested within it
          vars = V93K_SMT8::Processors::ExtractFlowVars.new.run(node.updated(:flow))
          @sub_flows ||= {}
          path = Pathname.new(node.find(:path).value)
          name = path.basename('.*').to_s
          @sub_flows[name] = "#{path.dirname}.#{name}".gsub(/(\/|\\)/, '.')
          input_variables(vars).each do |var|
            var = var[0] if var.is_a?(Array)
            line "#{name}.#{var} = #{var};"
          end
          line "#{name}.execute();"
        end

        def sub_flows
          @sub_flows || {}
        end
      end
    end
  end
end
