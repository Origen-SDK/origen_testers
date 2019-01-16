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
          vars[:all][:set_flags_extern].each do |var|
            var = var[0] if var.is_a?(Array)
            line "#{var} = #{name}.#{var};"
          end
        end

        def sub_flows
          @sub_flows || {}
        end

        def input_variables(vars = flow_variables)
          (vars[:all][:jobs] + vars[:all][:referenced_enables] + vars[:all][:set_enables]).uniq.sort do |x, y|
            x = x[0] if x.is_a?(Array)
            y = y[0] if y.is_a?(Array)
            x <=> y
          end
        end

        def output_variables(vars = flow_variables)
          (vars[:this_flow][:referenced_flags] + vars[:this_flow][:set_flags] + vars[:all][:set_flags_extern]).uniq.sort do |x, y|
            x = x[0] if x.is_a?(Array)
            y = y[0] if y.is_a?(Array)
            x <=> y
          end
        end
      end
    end
  end
end
