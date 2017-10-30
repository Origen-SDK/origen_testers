module OrigenTesters
  module SmartestBasedTester
    class Base
      class Flow < ATP::Formatter
        include OrigenTesters::Flow

        attr_accessor :test_suites, :test_methods, :lines, :stack, :var_filename
        # Returns an array containing all runtime variables which get set by the flow
        attr_reader :set_runtime_variables

        attr_accessor :add_flow_enable, :flow_name

        def var_filename
          @var_filename || 'global'
        end

        def subdirectory
          'testflow/mfh.testflow.group'
        end

        def filename
          super.gsub('_flow', '')
        end

        def flow_name
          @flow_name || filename.sub(/\..*/, '').upcase
        end

        def hardware_bin_descriptions
          @hardware_bin_descriptions ||= {}
        end

        def flow_control_variables
          Origen.interface.variables_file(self).flow_control_variables
        end

        def runtime_control_variables
          Origen.interface.variables_file(self).runtime_control_variables
        end

        def at_flow_start
          model # Call to ensure the signature gets populated
        end

        def at_flow_end
        end

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

        def finalize(options = {})
          super
          test_suites.finalize
          test_methods.finalize
          @indent = add_flow_enable ? 2 : 1
          @lines = []
          @stack = { on_fail: [], on_pass: [] }
          ast = atp.ast(unique_id: sig, optimization: :smt)
          @set_runtime_variables = ast.set_flags
          process(ast)
        end

        def line(str)
          @lines << ('  ' * @indent) + str
        end

        # def on_flow(node)
        #  line '{'
        #  @indent += 1
        #  process_all(node.children)
        #  @indent -= 1
        #  line "}, open,\"#{unique_group_name(node.find(:name).value)}\", \"\""
        # end

        def on_test(node)
          name = node.find(:object).to_a[0]
          name = name.name unless name.is_a?(String)
          if node.children.any? { |n| t = n.try(:type); t == :on_fail || t == :on_pass } ||
             !stack[:on_pass].empty? || !stack[:on_fail].empty?
            line "run_and_branch(#{name})"
            process_all(node.to_a.reject { |n| t = n.try(:type); t == :on_fail || t == :on_pass })
            line 'then'
            line '{'
            @indent += 1
            on_pass = node.children.find { |n| n.try(:type) == :on_pass }
            process_all(on_pass) if on_pass
            stack[:on_pass].each { |n| process_all(n) }
            @indent -= 1
            line '}'
            line 'else'
            line '{'
            @indent += 1
            on_fail = node.children.find { |n| n.try(:type) == :on_fail }
            process_all(on_fail) if on_fail
            stack[:on_fail].each { |n| process_all(n) }
            @indent -= 1
            line '}'
          else
            line "run(#{name});"
          end
        end

        def on_render(node)
          node.to_a[0].split("\n").each do |l|
            line(l)
          end
        end

        def on_if_job(node)
          jobs, *nodes = *node
          jobs = clean_job(jobs)
          state = node.type == :if_job
          runtime_control_variables << ['JOB', '']
          condition = jobs.join(' or ')
          line "if #{condition} then"
          line '{'
          @indent += 1
          process_all(node) if state
          @indent -= 1
          line '}'
          line 'else'
          line '{'
          @indent += 1
          process_all(node) unless state
          @indent -= 1
          line '}'
        end
        alias_method :on_unless_job, :on_if_job

        def on_condition_flag(node, state)
          flag, *nodes = *node
          else_node = node.find(:else)
          if flag.is_a?(Array)
            condition = flag.map { |f| "@#{generate_flag_name(f)} == 1" }.join(' or ')
          else
            condition = "@#{generate_flag_name(flag)} == 1"
          end
          line "if #{condition} then"
          line '{'
          @indent += 1
          if state
            process_all(node.children - [else_node])
          else
            process(else_node) if else_node
          end
          @indent -= 1
          line '}'
          line 'else'
          line '{'
          @indent += 1
          if state
            process(else_node) if else_node
          else
            process_all(node.children - [else_node])
          end
          @indent -= 1
          line '}'
        end

        def on_if_enabled(node)
          flag, *nodes = *node
          state = node.type == :if_enabled
          [flag].flatten.each do |f|
            flow_control_variables << generate_flag_name(f)
          end
          on_condition_flag(node, state)
        end
        alias_method :on_unless_enabled, :on_if_enabled

        def on_if_flag(node)
          flag, *nodes = *node
          state = node.type == :if_flag
          [flag].flatten.each do |f|
            runtime_control_variables << generate_flag_name(f)
          end
          on_condition_flag(node, state)
        end
        alias_method :on_unless_flag, :on_if_flag

        def on_enable(node)
          flag = node.value.upcase
          flow_control_variables << flag
          line "@#{flag} = 1;"
        end

        def on_disable(node)
          flag = node.value.upcase
          flow_control_variables << flag
          line "@#{flag} = 0;"
        end

        def on_set_flag(node)
          flag = generate_flag_name(node.value)
          runtime_control_variables << flag
          line "@#{flag} = 1;"
        end

        def on_group(node)
          on_fail = node.children.find { |n| n.try(:type) == :on_fail }
          on_pass = node.children.find { |n| n.try(:type) == :on_pass }
          line '{'
          @indent += 1
          stack[:on_fail] << on_fail if on_fail
          stack[:on_pass] << on_pass if on_pass
          process_all(node.children - [on_fail, on_pass])
          stack[:on_fail].pop if on_fail
          stack[:on_pass].pop if on_pass
          @indent -= 1
          line "}, open,\"#{unique_group_name(node.find(:name).value)}\", \"\""
        end

        def on_set_result(node)
          bin = node.find(:bin).try(:value)
          desc = node.find(:bin).to_a[1]
          sbin = node.find(:softbin).try(:value)
          sdesc = node.find(:softbin).to_a[1] || 'fail'
          if bin && desc
            hardware_bin_descriptions[bin] ||= desc
          end

          if node.to_a[0] == 'pass'
            line "stop_bin \"#{sbin}\", \"\", , good, noreprobe, green, #{bin}, over_on;"
          else
            line "stop_bin \"#{sbin}\", \"#{sdesc}\", , bad, noreprobe, red, #{bin}, over_on;"
          end
        end

        def on_log(node)
          line "print_dl(\"#{node.to_a[0]}\");"
        end

        def unique_group_name(name)
          @group_names ||= {}
          if @group_names[name]
            @group_names[name] += 1
            "#{name}_#{@group_names[name]}"
          else
            @group_names[name] = 1
            name
          end
        end

        def clean_job(job)
          [job].flatten.map { |j| "@JOB == \"#{j.to_s.upcase}\"" }
        end

        private

        def generate_flag_name(flag)
          case flag[0]
          when '$'
            flag[1..-1]
          else
            flag.upcase
          end
        end
      end
    end
  end
end
