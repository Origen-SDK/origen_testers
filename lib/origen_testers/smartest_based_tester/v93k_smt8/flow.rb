module OrigenTesters
  module SmartestBasedTester
    class V93K_SMT8
      require 'origen_testers/smartest_based_tester/base/flow'
      class Flow < Base::Flow
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k_smt8/templates/template.flow.erb"
        IN_IDENTIFIER = '_AUTOIN'

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
              line "if (!#{name}.pass) {"
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
          sub_flow = sub_flow_from(node)
          @sub_flows ||= {}
          path = Pathname.new(node.find(:path).value)
          name = path.basename('.*').to_s
          path = Origen.interface.smt8_sub_flow_path_overwrite(path) if Origen.interface.respond_to? :smt8_sub_flow_path_overwrite
          @sub_flows[name] = "#{path.dirname}.#{name}".gsub(/(\/|\\)/, '.')
          # Pass down all input variables before executing
          if sub_flow.input_variables.size > 0 && Origen.site_config.flow_variable_grouping
            line "// #{name} sub-flow input variables"
            line '{'
            @indent += 1
          end
          sub_flow.input_variables.each do |var|
            # Handle the inout variables
            # Get the main value into the temporary input variable
            if sub_flow.inout_variables.keys.include?(var)
              var = var[0] if var.is_a?(Array)
              line "#{name}.#{var} = #{sub_flow.inout_variables[var]};"
            else
              var = var[0] if var.is_a?(Array)
              line "#{name}.#{var} = #{var};"
            end
          end
          if sub_flow.input_variables.size > 0 && Origen.site_config.flow_variable_grouping
            @indent -= 1
            line '}'
          end
          line "#{name}.execute();"
          # And then retrieve all common output variables
          if (output_variables & sub_flow.output_variables).size > 0 && Origen.site_config.flow_variable_grouping
            line "// #{name} sub-flow output variables"
            line '{'
            @indent += 1
          end
          (output_variables & sub_flow.output_variables).sort.each do |var|
            var = var[0] if var.is_a?(Array)
            line "#{var} = #{name}.#{var};"
          end
          if (output_variables & sub_flow.output_variables).size > 0 && Origen.site_config.flow_variable_grouping
            @indent -= 1
            line '}'
          end
          if on_pass = node.find(:on_pass)
            pass_lines = capture_lines do
              @indent += 1
              pass_branch do
                process_all(on_pass) if on_pass
              end
              @indent -= 1
            end
            on_pass = nil if pass_lines.empty?
          end

          if on_fail = node.find(:on_fail)
            fail_lines = capture_lines do
              @indent += 1
              fail_branch do
                process_all(on_fail) if on_fail
              end
              @indent -= 1
            end
            on_fail = nil if fail_lines.empty?
          end

          if on_pass && !on_fail
            line "if (#{name}.pass) {"
            pass_lines.each { |l| line l, already_indented: true }
            line '}'

          elsif !on_pass && on_fail
            line "if (!#{name}.pass) {"
            fail_lines.each { |l| line l, already_indented: true }
            line '}'

          elsif on_pass && on_fail
            line "if (#{name}.pass) {"
            pass_lines.each { |l| line l, already_indented: true }
            line '} else {'
            fail_lines.each { |l| line l, already_indented: true }
            line '}'
          end
        end

        def on_auxiliary_flow(node)
          @auxiliary_flows ||= {}
          path = node.find(:path).value
          name = node.find(:name).value
          @auxiliary_flows[name] = "#{path}"
          line "#{name}.execute();"
        end

        def sub_flows
          @sub_flows || {}
        end

        def auxiliary_flows
          @auxiliary_flows || {}
        end

        def inout_variables
          @inout_variables || {}
        end

        # Variables which should be defined as an input to the current flow
        def input_variables
          vars = flow_variables
          # Jobs and enables flow into a sub-flow
          in_var_array = (vars[:all][:jobs] + vars[:all][:referenced_enables] + vars[:all][:set_enables] +
            # As do any flags which are referenced by it but which are not set within it
            (vars[:all][:referenced_flags] - vars[:all][:set_flags] - vars[:all][:unset_flags])).uniq
          identified_inout_variables = in_var_array.select { |e| output_variables.include?(e) }
          result = in_var_array.reject { |e| output_variables.include?(e) }
          @inout_variables = {}
          # create inout variables with unique ids to reduce user conflicts
          identified_inout_variables.each do |var|
            unique_id = 0
            var.each_byte { |n| unique_id += n }
            identifier = IN_IDENTIFIER + "_#{unique_id.to_s[0..4]}"
            @inout_variables[:"#{var}#{identifier}"] = var
          end
          result += @inout_variables.keys
          result.uniq.sort do |x, y|
            x = x[0] if x.is_a?(Array)
            y = y[0] if y.is_a?(Array)
            x.to_s <=> y.to_s
          end
        end

        # Variables which should be defined as an output of the current flow
        def output_variables
          vars = flow_variables
          # Flags that are set by this flow flow out of it
          (vars[:this_flow][:set_flags] +
           # As do any flags set by its children which are marked as external
           vars[:all][:set_flags_extern] +
           # Other test methods are setting the flags
           vars[:this_flow][:add_flags] +
           # Other test methods are set in the children
           vars[:all][:add_flags_extern] +
           # And any flags which are set by a child and referenced in this flow
           (vars[:this_flow][:referenced_flags] & vars[:sub_flows][:set_flags]) +
           # And also intermediate flags, those are flags which are set by a child and referenced
           # by a parent of the current flow
           intermediate_variables).uniq.sort do |x, y|
            x = x[0] if x.is_a?(Array)
            y = y[0] if y.is_a?(Array)
            x <=> y
          end
        end

        # Output variables which are not directly referenced by this flow, but which are referenced by a parent
        # flow and set by the given child flow and therefore must pass through the current flow.
        # By calling this method with no argument it will consider variables set by any child flow, alternatively
        # pass in the variables for the child flow in question and only that will be considered.
        def intermediate_variables(*sub_flows)
          set_flags = []
          all_sub_flows.each { |f| set_flags += f.flow_variables[:all][:set_flags] }
          if set_flags.empty?
            []
          else
            upstream_referenced_flags = []
            p = parent
            while p
              upstream_referenced_flags += p.flow_variables[:this_flow][:referenced_flags]
              p = p.parent
            end
            upstream_referenced_flags.uniq
            set_flags & upstream_referenced_flags
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
          # Handle the inout variables
          # Use the original variable name and get the value out of the temporary input variable
          inout_variables.each do |inout_var, orig_var|
            h << i + "#{orig_var} = #{inout_var};"
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
