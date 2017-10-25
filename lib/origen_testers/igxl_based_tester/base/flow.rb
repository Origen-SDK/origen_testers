module OrigenTesters
  module IGXLBasedTester
    class Base
      class Flow < ATP::Formatter
        include OrigenTesters::Flow

        OUTPUT_POSTFIX = 'flow'

        attr_reader :branch
        attr_reader :stack
        attr_reader :context
        # Keeps a note of the context under which flags where set
        attr_reader :set_flags
        attr_accessor :current_flag
        attr_accessor :current_enable

        class FlowLineAPI
          def initialize(flow)
            @flow = flow
          end

          def method_missing(method, *args, &block)
            if Base::FlowLine::DEFAULTS.key?(method.to_sym)
              line = @flow.platform::FlowLine.new(method, *args)
              @flow.render(line)
              line
            else
              super
            end
          end

          def respond_to?(method)
            !!Base::FlowLine::DEFAULTS.key?(method.to_sym)
          end
        end

        class TestCounter < ATP::Processor
          def run(node)
            @tests = 0
            process(node)
            @tests
          end

          def on_test(node)
            @tests += 1
          end
        end

        # Returns the API to manually generate an IG-XL flow line
        def ultraflex
          @flow_line_api ||= FlowLineAPI.new(self)
        end
        alias_method :uflex, :ultraflex
        alias_method :j750, :ultraflex

        def number_of_tests_in(node)
          @test_counter ||= TestCounter.new
          @test_counter.run(node)
        end

        # Will be called at the end to transform the final flow model into an array
        # of lines to be rendered to the IG-XL flow sheet
        def format
          @lines = []
          @stack = { jobs: [] }
          @context = []
          @set_flags = {}
          ast = atp.ast(unique_id: sig, optimization: :igxl)
          process(ast)
          lines
        end

        def on_flow(node)
          name, *nodes = *node
          process_all(nodes)
        end

        def on_test(node)
          line = new_line(:test) { |l| process_all(node) }

          # In IG-XL you can't set the same flag in case of pass or fail, that situation should
          # never occur unless the user has manually set up that condition
          if line.flag_fail && line.flag_fail == line.flag_pass
            fail "You can't set the same flag on test pass and fail in IG-XL!"
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

        def on_name(node)
          current_line.tname = node.to_a[0] if current_line
        end

        def on_number(node)
          if Origen.tester.diff_friendly_output?
            current_line.tnum = 0
          else
            current_line.tnum = node.to_a[0]
          end
        end

        def on_object(node)
          instance = node.to_a[0]
          if instance.is_a?(String)
            current_line.instance_variable_set('@ignore_missing_instance', true)
          end
          current_line.parameter = instance
        end

        def on_continue(node)
          current_line.result = 'None' if current_line
        end

        def on_set_flag(node)
          flag = clean_flag(node.to_a[0])
          set_flags[flag] = context.dup
          if current_line
            if branch == :on_fail
              current_line.flag_fail = flag
            else
              current_line.flag_pass = flag
            end
          else
            completed_lines << new_line(:flag_true, parameter: flag)
          end
        end

        def on_set_result(node)
          bin = node.find(:bin).try(:value)
          desc = node.find(:bin).to_a[1]
          sbin = node.find(:softbin).try(:value)
          if current_line
            if branch == :on_fail
              current_line.bin_fail = bin
              current_line.sort_fail = sbin
              current_line.comment = desc
              current_line.result = 'Fail'
            else
              current_line.bin_pass = bin
              current_line.sort_pass = sbin
              current_line.comment = desc
              current_line.result = 'Pass'
            end
          else
            line = new_line(:set_device)
            if node.to_a[0] == 'pass'
              line.bin_pass = bin
              line.sort_pass = sbin
              line.result = 'Pass'
            else
              line.bin_fail = bin
              line.sort_fail = sbin
              line.result = 'Fail'
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

        def on_if_job(node)
          jobs, *nodes = *node
          jobs = clean_job(jobs)
          state = node.type == :if_job
          unless state
            jobs = jobs.map { |j| "!#{j}" }
          end
          stack[:jobs] << [stack[:jobs].last, jobs].compact.join(',')
          context << stack[:jobs].last
          process_all(node)
          stack[:jobs].pop
          context.pop
        end
        alias_method :on_unless_job, :on_if_job

        def on_if_flag(node)
          flag, *nodes = *node
          orig = current_flag
          state = node.type == :if_flag
          if flag.is_a?(Array)
            or_flag = flag.join('_OR_')
            or_flag = "NOT_#{flag}" unless state
            flag.each do |f|
              if current_flag
                fail 'Not implemented yet!'
              else
                self.current_flag = [f, state]
                completed_lines << new_line(:flag_true, parameter: or_flag)
                self.current_flag = nil
              end
            end
            flag = or_flag
          end
          flag = clean_flag(flag)

          # If a flag condition is currently active
          if current_flag
            # If the current flag condition also gated the setting of this node's flag, then we
            # don't need to create an AND flag
            if !set_flags[flag] || (set_flags[flag] && set_flags[flag].hash != context.hash)
              and_flag = clean_flag(flag_to_s(*current_flag) + '_AND_' + flag_to_s(flag, state))
              # If the AND flag has already been created and set in this context (for a previous test),
              # no need to re-create it
              if !set_flags[and_flag] || (set_flags[and_flag].hash != context.hash)
                set_flags[and_flag] = context
                existing_flag = current_flag
                self.current_flag = nil
                completed_lines << new_line(:flag_true, parameter: and_flag)
                self.current_flag = [flag, !state]
                completed_lines << new_line(:flag_false, parameter: and_flag)
                self.current_flag = [existing_flag[0], !existing_flag[1]]
                completed_lines << new_line(:flag_false, parameter: and_flag)
              end
              flag = and_flag
            end
          end

          # Update the currently active flag condition, this will be added as a condition to all
          # lines created from children of this node
          self.current_flag = [flag, state]
          context << current_flag
          process_all(node)
          context.pop
          self.current_flag = orig
        end
        alias_method :on_unless_flag, :on_if_flag

        def on_if_enabled(node)
          flag, *nodes = *node
          orig = current_enable
          value = node.type == :if_enabled
          if flag.is_a?(Array)
            flag.map! { |a_flag| clean_enable(a_flag) }
            if flag.size > 1
              or_flag = flag.join('_OR_')
              flag.each do |f|
                completed_lines << new_line(:enable_flow_word, parameter: or_flag, enable: f)
              end
              flag = or_flag
            else
              flag = flag.first
            end
          else
            flag = clean_enable(flag)
          end
          if value
            # IG-XL docs say that enable words are not optimized for test time, so branch around
            # large blocks to minimize enable word evaluation
            if number_of_tests_in(node) > 5
              label = generate_unique_label
              branch_if_enable(flag) do
                completed_lines << new_line(:goto, parameter: label, enable: nil)
              end
              context << flag
              process_all(node)
              context.pop
              completed_lines << new_line(:nop, label: label, enable: nil)
            else
              if current_enable
                and_flag = "#{current_enable}_AND_#{flag}"
                label = generate_unique_label
                branch_if_enable(current_enable) do
                  completed_lines << new_line(:goto, parameter: label, enable: nil)
                end
                completed_lines << new_line(:enable_flow_word, parameter: and_flag, enable: flag)
                completed_lines << new_line(:nop, label: label, enable: nil)
                self.current_enable = and_flag
                context << and_flag
                process_all(node)
                context.pop
                self.current_enable = orig
              else
                self.current_enable = flag
                context << flag
                process_all(node)
                context.pop
                self.current_enable = orig
              end
            end
          else
            # IG-XL does not have a !enable option, so generate a branch around the tests
            # to be skipped unless the required flag is enabled
            context << "!#{flag}"
            branch_if_enable(flag) do
              process_all(node)
            end
            context.pop
          end
        end
        alias_method :on_unless_enabled, :on_if_enabled

        def branch_if_enable(word)
          label = generate_unique_label
          completed_lines << new_line(:goto, parameter: label, enable: word)
          yield
          completed_lines << new_line(:nop, label: label, enable: nil)
        end

        def on_enable(node)
          completed_lines << new_line(:enable_flow_word, parameter: node.value)
        end

        def on_disable(node)
          completed_lines << new_line(:disable_flow_word, parameter: node.value)
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
            enable: current_enable
          }.merge(attrs)
          line = platform::FlowLine.new(type, attrs)
          if current_flag
            line.device_sense = 'not' unless current_flag[1]
            line.device_name = clean_flag(current_flag[0])
            line.device_condition = 'flag-true'
          end
          open_lines << line
          yield line if block_given?
          open_lines.pop
          line
        end

        # Any completed lines should be pushed to the array that this returns
        def completed_lines
          lines
        end

        def open_lines
          @open_lines ||= []
        end

        def current_line
          open_lines.last
        end

        def clean_job(job)
          [job].flatten.map { |j| j.to_s.upcase }
        end

        def flag_to_s(flag, state)
          if state
            flag
          else
            "NOT_#{flag}"
          end
        end

        private

        def clean_enable(flag)
          flag = flag.to_s
          if flag[0] == '$'
            flag[0] = ''
            flag
          else
            flag.downcase
          end
        end

        def clean_flag(flag)
          flag = flag.to_s
          if flag[0] == '$'
            flag[0] = ''
          end
          flag
        end
      end
    end
  end
end
