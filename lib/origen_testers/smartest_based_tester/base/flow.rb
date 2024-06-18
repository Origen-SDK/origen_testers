require 'origen_testers/smartest_based_tester/base/processors/extract_flow_vars'
module OrigenTesters
  module SmartestBasedTester
    class Base
      class Flow < ATP::Formatter
        include OrigenTesters::Flow

        RELATIONAL_OPERATOR_STRINGS = {
          eq: '==',
          ne: '!=',
          gt: '>',
          ge: '>=',
          lt: '<',
          le: '<='
        }

        attr_accessor :test_suites, :test_methods, :lines, :stack, :var_filename
        # Returns an array containing all runtime variables which get set by the flow
        attr_reader :set_runtime_variables

        attr_accessor :add_flow_enable, :flow_name, :flow_bypass, :flow_description, :subdirectory

        def self.generate_flag_name(flag)
          case flag[0]
          when '$'
            flag[1..-1]
          else
            flag.upcase
          end
        end

        def smt8?
          tester.smt8?
        end

        def var_filename
          @var_filename || 'global'
        end

        def set_var_filename(new_var_filename)
          @var_filename = new_var_filename
        end

        def subdirectory
          @subdirectory ||= begin
            if smt8?
              parents = []
              f = parent
              while f
                parents.unshift(File.basename(f.filename, '.*').to_s.downcase)
                f = f.parent
              end
              if Origen.interface.respond_to?(:insertion) && tester.insertion_in_the_flow_path
                File.join tester.package_namespace, Origen.interface.insertion.to_s, 'flows', *parents
              else
                File.join tester.package_namespace, 'flows', *parents
              end
            else
              'testflow/mfh.testflow.group'
            end
          end
        end

        def filename
          base = super.gsub('_flow', '')
          if smt8?
            flow_name(base) + '.flow'
          else
            base
          end
        end

        def flow_enable_var_name
          var = filename.sub(/\..*/, '').upcase
          if smt8?
            'ENABLE'
          else
            generate_flag_name("#{var}_ENABLE")
          end
        end

        def flow_name(filename = nil)
          @flow_name_ = @flow_name unless smt8?
          @flow_name_ ||= begin
            flow_name = (filename || self.filename).sub(/\..*/, '').upcase
            if smt8?
              flow_name.gsub(' ', '_')
            else
              flow_name
            end
          end
        end

        def flow_bypass
          @flow_bypass || false
        end

        def flow_description
          @flow_description || ''
        end

        def hardware_bin_descriptions
          @hardware_bin_descriptions ||= {}
        end

        def flow_variables
          @flow_variables ||= begin
            vars = Processors::ExtractFlowVars.new.run(ast)
            if !smt8? || (smt8? && top_level?)
              if add_flow_enable
                if add_flow_enable == :enabled
                  vars[:all][:referenced_enables] << [flow_enable_var_name, 1]
                  vars[:this_flow][:referenced_enables] << [flow_enable_var_name, 1]
                else
                  vars[:all][:referenced_enables] << [flow_enable_var_name, 0]
                  vars[:this_flow][:referenced_enables] << [flow_enable_var_name, 0]
                end
                vars[:empty?] = false
              end
            end
            vars
          end
        end

        def at_flow_start
          model # Call to ensure the signature gets populated
        end

        def on_top_level_set
          if top_level?
            if smt8?
              @limits_file = platform::LimitsFile.new(self, manually_register: true, filename: filename.sub(/\..*/, ''), test_modes: @test_modes)
            else
              @limits_file = platform::LimitsFile.new(self, manually_register: true, filename: "#{name}_limits", test_modes: @test_modes)
            end
          else
            @limits_file = top_level.limits_file
          end
        end

        def limits_file
          @limits_file
        end

        def at_flow_end
          # Take whatever the test modes are set to at the end of the flow as what we go with
          @test_modes = tester.limitfile_test_modes
        end

        def ast
          @ast = nil unless @finalized
          @ast ||= begin
            unique_id = smt8? ? nil : sig
            atp.ast(unique_id: unique_id, optimization: :smt,
                  implement_continue: !tester.force_pass_on_continue,
                  optimize_flags_when_continue: !tester.force_pass_on_continue
                   )
          end
        end

        # Returns an array containing all sub-flow objects, not just the immediate children
        def all_sub_flows
          @all_sub_flows ||= begin
            sub_flows = []
            extract_sub_flows(self, sub_flows)
            sub_flows
          end
        end

        # @api private
        def extract_sub_flows(flow, sub_flows)
          flow.children.each do |id, sub_flow|
            sub_flows << sub_flow
            extract_sub_flows(sub_flow, sub_flows)
          end
          sub_flows
        end

        # Returns the sub_flow object corresponding to the given sub_flow AST
        def sub_flow_from(sub_flow_ast)
          path = sub_flow_ast.find(:path).value
          sub_flow = all_sub_flows.find { |f| File.join(f.subdirectory, f.filename) == path }
        end

        # This is called by Origen on each flow after they have all been executed but before they
        # are finally written/rendered
        def finalize(options = {})
          if smt8?
            return unless top_level? || options[:called_by_top_level]
            super
            @finalized = true
            # All flows have now been executed and the top-level contains the final AST.
            # The AST contained in each child flow may not be complete since it has not been subject to the
            # full-flow processing, e.g. to set flags in the event of a reference to a test being made from
            # outside of a sub-flow.
            # So here we substitute the AST in all sub-flows with the corresponding sub-flow node from the
            # top-level AST, then we finalize the sub-flows with the final AST in place and then later final
            # writing/rendering will be called as normal.
            if top_level?
              ast.find_all(:sub_flow, recursive: true).each do |sub_flow_ast|
                sub_flow = sub_flow_from(sub_flow_ast)
                unless sub_flow
                  fail "Something went wrong, couldn't find the sub-flow object for path #{path}"
                end
                # on_fail and on_pass nodes are removed because they will be rendered by the sub-flow's parent
                sub_flow.instance_variable_set(:@ast, sub_flow_ast.remove(:on_fail, :on_pass).updated(:flow))
                sub_flow.instance_variable_set(:@finalized, true)  # To stop the AST being regenerated
              end
              options[:called_by_top_level] = true
              all_sub_flows.each { |f| f.finalize(options) }
              options.delete(:called_by_top_level)
            end
          else
            super
            @finalized = true
          end
          if smt8?
            @indent = (add_flow_enable && top_level?) ? 3 : 2
          else
            @indent = add_flow_enable ? 2 : 1
          end
          @lines = []
          @lines_buffer = []
          @open_test_methods = []
          @open_test_names = []
          @post_test_lines = []
          @stack = { on_fail: [], on_pass: [] }
          @set_runtime_variables = ast.excluding_sub_flows.set_flags
          global_flags.each do |global_var_name|
            @set_runtime_variables.delete(global_var_name)
            @set_runtime_variables.delete('$' + global_var_name)
          end
          process(ast)
          unless smt8?
            unless flow_variables[:empty?]
              Origen.interface.variables_file(self).add_variables(flow_variables)
            end
          end
          test_suites.finalize
          test_methods.finalize
          if tester.create_limits_file && top_level?
            render_limits_file
          end
        end

        def render_limits_file
          if limits_file
            limits_file.test_modes = @test_modes
            limits_file.generate(ast)
            limits_file.write_to_file
          end
        end

        def line(str, options = {})
          if options[:already_indented]
            line = str
          else
            if smt8?
              line = ('    ' * @indent) + str
            else
              line = '    ' + ('   ' * (@indent - 1)) + str
            end
          end
          if @lines_buffer.last
            @lines_buffer.last << line
          else
            @lines << line
          end
        end

        # Any calls to line made within the given block will be returned in an array, rather than
        # immediately being put into the @lines array
        def capture_lines
          @lines_buffer << []
          yield
          @lines_buffer.pop
        end

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
            if smt8?
              line "#{name}.execute();"
            else
              line "run_and_branch(#{name})"
            end
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

            if smt8?
              line "if (#{name}.pass) {"
            else
              line 'then'
              line '{'
            end
            @indent += 1
            pass_branch do
              process_all(on_pass) if on_pass
              stack[:on_pass].each { |n| process_all(n) }
            end
            @indent -= 1
            if smt8?
              line '} else {'
            else
              line '}'
              line 'else'
              line '{'
            end
            @indent += 1
            fail_branch do
              process_all(on_fail) if on_fail
              stack[:on_fail].each { |n| process_all(n) }
            end
            @indent -= 1
            line '}'

            @open_test_methods.pop
          else
            if smt8?
              line "#{name}.execute();"
            else
              line "run(#{name});"
            end
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
          if smt8?
            if jobs.size == 1
              condition = jobs.first
            else
              condition = jobs.map { |j| "(#{j})" }.join(' || ')
            end
            line "if (#{condition}) {"
          else
            condition = jobs.join(' or ')
            line "if #{condition} then"
            line '{'
          end
          @indent += 1
          process_all(node) if state
          @indent -= 1
          if smt8?
            line '} else {'
          else
            line '}'
            line 'else'
            line '{'
          end
          @indent += 1
          process_all(node) unless state
          @indent -= 1
          line '}'
        end
        alias_method :on_unless_job, :on_if_job

        def on_condition_flag(node, state)
          flag, *nodes = *node
          else_node = node.find(:else)
          if smt8?
            if flag.is_a?(Array)
              condition = flag.map { |f| "(#{generate_flag_name(f)} == 1)" }.join(' || ')
            else
              condition = "#{generate_flag_name(flag)} == 1"
            end
            line "if (#{condition}) {"
          else
            if flag.is_a?(Array)
              condition = flag.map { |f| "@#{generate_flag_name(f)} == 1" }.join(' or ')
            else
              condition = "@#{generate_flag_name(flag)} == 1"
            end
            line "if #{condition} then"
            line '{'
          end
          @indent += 1
          if state
            process_all(node.children - [else_node])
          else
            process(else_node) if else_node
          end
          @indent -= 1
          if smt8?
            line '} else {'
          else
            line '}'
            line 'else'
            line '{'
          end
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
          on_condition_flag(node, state)
        end
        alias_method :on_unless_enabled, :on_if_enabled

        def on_if_flag(node)
          flag, *nodes = *node
          state = node.type == :if_flag
          on_condition_flag(node, state)
        end
        alias_method :on_unless_flag, :on_if_flag

        def on_whenever(node)
          expressions, *nodes = *node
          and_string = ' and '
          or_string  = ' or '
          if smt8?
            and_string = ' && '
            or_string  = ' || '
          end
          case node.type
          when :whenever_all
            condition = expressions.map { |e| "#{generate_expr_string(e)}" }.join(and_string)
          when :whenever_any
            condition = expressions.map { |e| "#{generate_expr_string(e)}" }.join(or_string)
          else
            condition = expressions.map { |e| "#{generate_expr_string(e)}" }.join('ERROR')
          end

          if smt8?
            line "if (#{condition})"
          else
            line "if #{condition} then"
          end
          line '{'
          @indent += 1
          process_all(node.children)
          @indent -= 1
          line '}'
          line 'else'
          line '{'
          line '}'
        end
        alias_method :on_whenever_any, :on_whenever
        alias_method :on_whenever_all, :on_whenever

        def on_loop(node, options = {})
          start = node.to_a[0]
          if start.is_a?(String)
            start = generate_flag_name(start)
            unless smt8?
              start = "@#{start}"
            end
          end
          stop = node.to_a[1]
          if stop.is_a?(String) && smt8?
            stop = generate_flag_name(stop)
          elsif stop.is_a?(String)
            fail 'loops with \'stop\' defined as a variable cannot be supported in the defined environments.'
          end
          step = node.to_a[2]
          if smt8? && !(step == -1 || step == 1)
            fail 'SMT8 does not support steps other than -1 or 1.'
          end
          if node.to_a[3].nil?
            fail 'You must supply a loop variable name!'
          else
            var = generate_flag_name(node.to_a[3])
          end
          test_num_inc = node.to_a[4]
          unless smt8?
            var = "@#{var}"
          end
          # num = (stop - start) / step + 1
          # Handle increment/decrement
          if step < 0
            compare = '>'
            incdec = "- #{step * -1}"
          else
            compare = '<'
            incdec = "+ #{step}"
          end
          if tester.smt7?
            line "for #{var} = #{start}; #{var} #{compare} #{stop + step} ; #{var} = #{var} #{incdec}; do"
            line "test_number_loop_increment = #{test_num_inc}"
            line '{'
            @indent += 1
            process_all(node.children)
            @indent -= 1
            line '}'
          elsif smt8?
            line "for (#{var} : #{start}..#{stop})"
            line '{'
            @indent += 1
            process_all(node.children)
            @indent -= 1
            line '}'
          else
            fail 'Environment was not supported for flow loops.'
          end
        end

        def generate_expr_string(node, options = {})
          return node unless node.respond_to?(:type)
          case node.type
          when :eq, :ne, :gt, :ge, :lt, :le
            result = "#{generate_expr_term(node.to_a[0])} "             # operand 1
            result += "#{RELATIONAL_OPERATOR_STRINGS[node.type]} "      # relational condition
            result += "#{generate_expr_term(node.to_a[1])}"             # operand 2
            result
          else
            fail "Relational operator '#{node.type}' not  supported"
          end
        end

        def generate_expr_term(val)
          return val if val.is_a?(Fixnum) || val.is_a?(Integer) || val.is_a?(Float)
          case val[0]
          when '$'
            if smt8?
              "#{val[1..-1]}"
            else
              "@#{val[1..-1]}"
            end
          else
            if val.is_a? String
              "\"#{val}\""
            else
              val
            end
          end
        end

        def on_set(node)
          flag = generate_flag_name(node.to_a[0])
          val = generate_expr_term(node.to_a[1])
          if smt8?
            line "#{flag} = #{val};"
          else
            line "@#{flag} = #{val};"
          end
        end

        def on_enable(node)
          flag = node.value.upcase
          if smt8?
            line "#{flag} = 1;"
          else
            line "@#{flag} = 1;"
          end
        end

        def on_disable(node)
          flag = node.value.upcase
          if smt8?
            line "#{flag} = 0;"
          else
            line "@#{flag} = 0;"
          end
        end

        def on_set_flag(node)
          flag = generate_flag_name(node.value)
          # This means if we are currently generating an on_test node and tester.force_pass_on_continue has been set
          if @open_test_methods.last
            if pass_branch?
              if smt8?
                @post_test_lines.last << "#{flag} = #{@open_test_names.last}.setOnPassFlags;"
              else
                if @open_test_methods.last.respond_to?(:on_pass_flag)
                  if @open_test_methods.last.on_pass_flag == ''
                    @open_test_methods.last.on_pass_flag = flag
                  else
                    Origen.log.error "The test method cannot set #{flag} on passing, because it already sets: #{@open_test_methods.last.on_pass_flag}"
                    Origen.log.error "  #{node.source}"
                    exit 1
                  end
                else
                  Origen.log.error 'Force pass on continue has been requested, but the test method does not have an :on_pass_flag attribute:'
                  Origen.log.error "  #{node.source}"
                  exit 1
                end
              end
            else
              if smt8?
                @post_test_lines.last << "#{flag} = #{@open_test_names.last}.setOnFailFlags;"
              else
                if @open_test_methods.last.respond_to?(:on_fail_flag)
                  if @open_test_methods.last.on_fail_flag == ''
                    @open_test_methods.last.on_fail_flag = flag
                  else
                    Origen.log.error "The test method cannot set #{flag} on failing, because it already sets: #{@open_test_methods.last.on_fail_flag}"
                    Origen.log.error "  #{node.source}"
                    exit 1
                  end
                else
                  Origen.log.error 'Force pass on continue has been requested, but the test method does not have an :on_fail_flag attribute:'
                  Origen.log.error "  #{node.source}"
                  exit 1
                end
              end
            end
          else
            if smt8?
              line "#{flag} = 1;"
            else
              line "@#{flag} = 1;"
            end
          end
        end

        def on_unset_flag(node)
          flag = generate_flag_name(node.value)
          if smt8?
            line "#{flag} = 0;"
          else
            line "@#{flag} = 0;"
          end
        end

        # Note that for smt8?, this should never be hit anymore since groups are now generated as sub-flows
        def on_group(node)
          on_fail = node.children.find { |n| n.try(:type) == :on_fail }
          on_pass = node.children.find { |n| n.try(:type) == :on_pass }
          group_name = unique_group_name(node.find(:name).value)
          if smt8?
            line '// *******************************************************'
            line "// GROUP - #{group_name}"
            line '// *******************************************************'
          else
            line '{'
          end
          @indent += 1
          stack[:on_fail] << on_fail if on_fail
          stack[:on_pass] << on_pass if on_pass
          process_all(node.children - [on_fail, on_pass])
          stack[:on_fail].pop if on_fail
          stack[:on_pass].pop if on_pass
          @indent -= 1
          bypass = node.find(:bypass).try(:value) || flow_bypass
          comment = node.find(:comment).try(:value) || ''
          if smt8?
            line '// *******************************************************'
            line "// /GROUP - #{group_name}"
            line '// *******************************************************'
          else
            if bypass
              line "}, groupbypass, open,\"#{group_name}\", \"\""
            else
              line "}, open,\"#{group_name}\", \"\""
            end
          end
        end

        def on_set_result(node)
          bin = node.find(:bin).try(:value)
          desc = node.find(:bin).to_a[1]
          sbin = node.find(:softbin).try(:value)
          sdesc = node.find(:softbin).to_a[1] || 'fail'
          overon = (node.find(:not_over_on).try(:value) == true) ? 'not_over_on' : 'over_on'
          if bin && desc
            hardware_bin_descriptions[bin] ||= desc
          end

          if smt8?
            # Currently only rendering pass bins or those not associated with a test (should come from the bin
            # table if its associated with a test)
            if node.to_a[0] == 'pass' || @open_test_methods.empty?
              line "addBin(#{sbin || bin});"
            end
          else
            if node.to_a[0] == 'pass'
              line "stop_bin \"#{sbin}\", \"\", , good, noreprobe, green, #{bin}, over_on;"
            else
              if tester.create_limits_file
                line 'multi_bin;'
              else
                line "stop_bin \"#{sbin}\", \"#{sdesc}\", , bad, noreprobe, red, #{bin}, #{overon};"
              end
            end
          end
        end

        def on_log(node)
          if smt8?
            line "println(\"#{node.to_a[0]}\");"
          else
            line "print_dl(\"#{node.to_a[0]}\");"
          end
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
          var = smt8? ? 'JOB' : '@JOB'
          [job].flatten.map { |j| "#{var} == \"#{j.to_s.upcase}\"" }
        end

        private

        def pass_branch
          open_branch_types << :pass
          yield
          open_branch_types.pop
        end

        def fail_branch
          open_branch_types << :fail
          yield
          open_branch_types.pop
        end

        def pass_branch?
          open_branch_types.last == :pass
        end

        def fail_branch?
          open_branch_types.last == :fail
        end

        def open_branch_types
          @open_branch_types ||= []
        end

        def generate_flag_name(flag)
          self.class.generate_flag_name(flag)
        end
      end
    end
  end
end
