module OrigenTesters
  module SmartestBasedTester
    class V93K_SMT8
      require 'origen_testers/smartest_based_tester/base/flow'
      class Flow < Base::Flow
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k_smt8/templates/template.flow.erb"

        def on_test(node)
          test_suite = node.find(:object).to_a[0]
          if test_suite.is_a?(String)
            name = test_suite
          else
            name = test_suite.name
            test_method = test_suite.test_method
            if test_method.respond_to?(:test_name) && test_method.test_name == '' &&
               n = node.find(:name)
              test_method.test_name = n.value
            end
          end

          if node.children.any? { |n| t = n.try(:type); t == :on_fail || t == :on_pass } ||
             !stack[:on_pass].empty? || !stack[:on_fail].empty?
            line "#{name}.execute();"
            @open_test_names << name
            @post_test_lines << []
            process_all(node.to_a.reject { |n| t = n.try(:type); t == :on_fail || t == :on_pass })
            on_pass = node.find(:on_pass)
            on_fail = node.find(:on_fail)

            if on_fail && on_fail.find(:continue) && tester.force_pass_on_continue
              if test_method.respond_to?(:force_pass)
                test_method.force_pass = 1
              else
                Origen.log.error 'Force pass on continue has been enabled, but the test method does not have a force_pass attribute!'
                Origen.log.error "  #{node.source}"
                exit 1
              end
              @open_test_methods << test_method
            else
              if test_method.respond_to?(:force_pass)
                test_method.force_pass = 0
              end
              @open_test_methods << nil
            end

            pass_lines = capture_lines do
              @indent += 1
              pass_branch do
                process_all(on_pass) if on_pass
                stack[:on_pass].each { |n| process_all(n) }
              end
              @indent -= 1
            end

            fail_lines = capture_lines do
              @indent += 1
              fail_branch do
                process_all(on_fail) if on_fail
                stack[:on_fail].each { |n| process_all(n) }
              end
              @indent -= 1
            end

            if !pass_lines.empty? && fail_lines.empty?
              line "if (#{name}.pass) {"
              pass_lines.each { |l| line l, already_indented: true }
              line '}'

            elsif pass_lines.empty? && !fail_lines.empty?
              line "if (#{name}.fail) {"
              fail_lines.each { |l| line l, already_indented: true }
              line '}'

            elsif !pass_lines.empty? && !fail_lines.empty?
              line "if (#{name}.pass) {"
              pass_lines.each { |l| line l, already_indented: true }
              line '} else {'
              fail_lines.each { |l| line l, already_indented: true }
              line '}'

            end

            @open_test_methods.pop
            @open_test_names.pop
            @post_test_lines.pop.each { |l| line(l) }
          else
            line "#{name}.execute();"
          end
        end

        def on_sub_flow(node)
          # In the returned vars :this_flow means this sub_flow, :sub_flows refers to any further
          # sub_flows that are nested within it
          vars = V93K_SMT8::Processors::ExtractFlowVars.new.run(node.updated(:flow))
          @sub_flows ||= {}
          path = Pathname.new(node.find(:path).value)
          name = path.basename('.*').to_s
          @sub_flows[name] = "#{path.dirname}.#{name}".gsub(/(\/|\\)/, '.')
          # Pass down all input variables (enables) that are referenced by this sub_flow or any
          # of its children
          input_variables(vars).each do |var|
            var = var[0] if var.is_a?(Array)
            line "#{name}.#{var} = #{var};"
          end
          line "#{name}.execute();"
          sub_flow = sub_flow_from(node)
          (vars[:all][:set_flags_extern] + intermediate_variables(sub_flow.flow_variables[:all][:set_flags])).each do |var|
            var = var[0] if var.is_a?(Array)
            line "#{var} = #{name}.#{var};"
          end
        end

        def sub_flows
          @sub_flows || {}
        end

        # Variables which should be defined as an input to the current flow
        def input_variables(vars = flow_variables)
          (vars[:all][:jobs] + vars[:all][:referenced_enables] + vars[:all][:set_enables]).uniq.sort do |x, y|
            x = x[0] if x.is_a?(Array)
            y = y[0] if y.is_a?(Array)
            x <=> y
          end
        end

        # Variables which should be defined as an output of the current flow
        def output_variables(vars = flow_variables)
          (vars[:this_flow][:referenced_flags] + vars[:this_flow][:set_flags] + vars[:all][:set_flags_extern] +
           intermediate_variables).uniq.sort do |x, y|
            x = x[0] if x.is_a?(Array)
            y = y[0] if y.is_a?(Array)
            x <=> y
          end
        end

        # Output variables which are not directly referenced by this flow, but which are referenced by a parent
        # flow and set by a child flow and therefore must pass through the current flow.
        # By calling this method with no argument it will consider variables set by any child flow, alternatively
        # pass in the variables for the child flow in question and only that will be considered.
        def intermediate_variables(set_vars = flow_variables[:all][:set_flags])
          if set_vars.empty?
            []
          else
            upstream_referenced_flags = []
            p = parent
            while p
              upstream_referenced_flags += p.flow_variables[:this_flow][:referenced_flags]
              p = p.parent
            end
            upstream_referenced_flags.uniq!
            set_vars & upstream_referenced_flags
          end
        end

        def flow_header
          h = []
          if add_flow_enable && top_level?
            h << "        if (#{flow_enable_var_name} == 1) {"
            i = '            '
          else
            i = '        '
          end
          flow_variables[:this_flow][:set_flags].each do |var|
            if var.is_a?(Array)
              h << i + "#{var[0]} = #{var[1].is_a?(String) || var[1].is_a?(Symbol) ? '"' + var[1].to_s + '"' : var[1]};"
            else
              h << i + "#{var} = -1;"
            end
          end
          h << '' unless flow_variables[:this_flow][:set_flags].empty?
          h
        end

        def flow_footer
          f = []
          if add_flow_enable && top_level?
            f << '        }'
          end
          f
        end
      end
    end
  end
end
