module OrigenTesters
  module IGXLBasedTester
    class Base
      class Flow < ATP::Formatter
        include OrigenTesters::Flow

        OUTPUT_POSTFIX = 'flow'

        attr_reader :branch
        attr_reader :stack
        attr_reader :current_group
        attr_accessor :run_flag

        # Will be called at the end to transform the final flow model into an array
        # of lines to be rendered to the IG-XL flow sheet
        def format
          @lines = []
          @stack = { jobs: [], run_flags: [], flow_flags: [], groups: [] }
          process(model.ast)
          lines
        end

        def on_test(node)
          line = new_line(:test) { |l| process_all(node) }

          # In IG-XL you can't set the same flag in case of pass or fail, if that situation has
          # occurred then rectify it now
          if line.flag_fail && line.flag_fail == line.flag_pass
            # If the test will bin, don't need to resolve the situation, the flag only matters
            # in the pass case
            if line.result = 'Fail'
              line.flag_fail = nil
              completed_lines << line
            else
              flag = line.flag_fail
              line.flag_fail = "#{flag}_FAILED"
              line.flag_pass = "#{flag}_PASSED"
              completed_lines << line
              existing_flag = run_flag
              self.run_flag = [line.flag_fail, true]
              completed_lines << new_line(:flag_true, parameter: flag)
              self.run_flag = [line.flag_pass, true]
              completed_lines << new_line(:flag_true, parameter: flag)
              self.run_flag = existing_flag
            end
          else
            completed_lines << line
          end
        end

        def on_cz(node)
          setup, test = *node
          completed_lines << new_line(:cz, cz_setup: setup) do |line|
            process_all(test)
          end
        end

        def on_group(node)
          stack[:groups] << []
          process_all(node.find(:members))
          # Now process any on_fail and similar conditional logic attached to the group
          @current_group = stack[:groups].last
          process_all(node)
          @current_group = nil
          flags = { on_pass: [], on_fail: [] }
          stack[:groups].pop.each do |test|
            flags[:on_pass] << test.flag_pass
            flags[:on_fail] << test.flag_fail
            completed_lines << test
          end
          if @group_on_fail_flag
            flags[:on_fail].each do |flag|
              self.run_flag = [flag, true]
              completed_lines << new_line(:flag_true, parameter: @group_on_fail_flag)
            end
            self.run_flag = nil
            @group_on_fail_flag = nil
          end
          if @group_on_pass_flag
            flags[:on_pass].each do |flag|
              self.run_flag = [flag, true]
              completed_lines << new_line(:flag_true, parameter: @group_on_pass_flag)
            end
            self.run_flag = nil
            @group_on_pass_flag = nil
          end
        end

        def on_members(node)
          # Do nothing, will be processed directly by the on_group handler
        end

        def on_name(node)
          if current_group
            # No action, groups will not actually appear in the flow sheet
          else
            current_line.tname = node.to_a[0]
          end
        end

        def on_number(node)
          current_line.tnum = node.to_a[0]
        end

        def on_object(node)
          instance = node.to_a[0]
          if instance.is_a?(String)
            current_line.instance_variable_set('@ignore_missing_instance', true)
          end
          current_line.parameter = instance
        end

        def on_continue(node)
          if current_group
            current_group.each { |line| line.result = 'None' }
          else
            current_line.result = 'None'
          end
        end

        def on_set_run_flag(node)
          flag = node.to_a[0]
          if current_group
            if branch == :on_fail
              @group_on_fail_flag = flag
              current_group.each_with_index do |line, i|
                line.flag_fail = "#{flag}_#{i}" unless line.flag_fail
              end
            else
              @group_on_pass_flag = flag
              current_group.each_with_index do |line, i|
                line.flag_pass = "#{flag}_#{i}" unless line.flag_pass
              end
            end
          else
            if branch == :on_fail
              current_line.flag_fail = flag
            else
              current_line.flag_pass = flag
            end
          end
        end

        def on_set_result(node)
          bin = node.find(:bin).try(:value)
          sbin = node.find(:softbin).try(:value)
          desc = node.find(:description).try(:value)
          if current_line
            if branch == :on_fail
              current_line.bin_fail = bin
              current_line.sort_fail = sbin
              current_line.comment = desc
            else
              current_line.bin_pass = bin
              current_line.sort_pass = sbin
              current_line.comment = desc
            end
          else
            line = new_line(:set_device)
            if node.to_a[0] == 'pass'
              line.bin_pass = bin
              line.sort_pass = sbin
            else
              line.bin_fail = bin
              line.sort_fail = sbin
            end
            line.comment = desc
            completed_lines << line
          end
        end

        def on_on_fail(node)
          @branch = :on_fail
          process_all(node)
          @branch = nil
        end

        def on_on_pass(node)
          @branch = :on_pass
          process_all(node)
          @branch = nil
        end

        def on_job(node)
          job = clean_job(node.to_a[0])
          stack[:jobs] << [stack[:jobs].last, job].compact.join(',')
          process_all(node)
          stack[:jobs].pop
        end

        def on_run_flag(node)
          flag, state, *nodes = *node
          if flag.is_a?(Array)
            or_flag = flag.join('_OR_')
            or_flag = "NOT_#{flag}" unless state
            flag.each do |f|
              if run_flag
                fail 'Not implemented yet!'
              else
                self.run_flag = [f, state]
                completed_lines << new_line(:flag_true, parameter: or_flag)
                self.run_flag = nil
              end
            end
            if run_flag
              and_flag = flag_to_s(or_flag, state) + '_AND_' + flag_to_s(*run_flag)
              self.run_flag = [and_flag, true]
            else
              self.run_flag = [or_flag, true]
            end
          else
            if run_flag
              and_flag = flag_to_s(flag, state) + '_AND_' + flag_to_s(*run_flag)
              existing_flag = run_flag
              self.run_flag = nil
              completed_lines << new_line(:flag_true, parameter: and_flag)
              self.run_flag = [existing_flag[0], !existing_flag[1]]
              completed_lines << new_line(:flag_false, parameter: and_flag)
              self.run_flag = [flag, !state]
              completed_lines << new_line(:flag_false, parameter: and_flag)
              self.run_flag = [and_flag, true]
            else
              self.run_flag = [flag, state]
            end
          end
          process_all(node)
          self.run_flag = nil
        end

        def on_flow_flag(node)
          flag, value = *node.to_a.take(2)
          if flag.is_a?(Array)
            if flag.size > 1
              fail 'Multi-condition flow flags are not implemented for Teradyne platforms yet'
            else
              flag = flag.first
            end
          end
          if value
            stack[:flow_flags] << flag
            process_all(node)
            stack[:flow_flags].pop
          else
            # IG-XL does not have a !enable option, so generate a branch around the tests
            # to be skipped unless the required flag is enabled
            label = generate_unique_label
            completed_lines << new_line(:goto, parameter: label, enable: flag)
            process_all(node)
            completed_lines << new_line(:nop, label: label)
          end
        end

        def on_log(node)
          completed_lines << new_line(:logprint, parameter: node.to_a[0].gsub(' ', '_'))
        end

        def on_render(node)
          completed_lines << node.to_a[0]
        end

        def new_line(type, attrs = {})
          attrs = {
            job:    stack[:jobs].last,
            enable: stack[:flow_flags].last
          }.merge(attrs)
          line = platform::FlowLine.new(type, attrs)
          if run_flag
            line.device_sense = 'not' unless run_flag[1]
            line.device_name = run_flag[0]
            line.device_condition = 'flag-true'
          end
          open_lines << line
          yield line if block_given?
          open_lines.pop
          line
        end

        # Any completed lines should be pushed to the array that this returns
        def completed_lines
          stack[:groups].last || lines
        end

        def open_lines
          @open_lines ||= []
        end

        def current_line
          open_lines.last
        end

        def clean_job(job)
          if job.try(:type) == :or
            job.to_a.map { |j| clean_job(j) }.join(',')
          elsif job.try(:type) == :not
            clean_job(job.to_a[0]).split(',').map { |j| "!#{j}" }.join(',')
          else
            job.upcase
          end
        end

        def flag_to_s(flag, state)
          if state
            flag
          else
            "NOT_#{flag}"
          end
        end
      end
    end
  end
end
