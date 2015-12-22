module OrigenTesters
  module IGXLBasedTester
    class Base
      class Flow < ATP::Formatter
        include OrigenTesters::Flow

        OUTPUT_POSTFIX = 'flow'

        attr_reader :branch
        attr_reader :stack
        attr_accessor :run_flag

        # Will be called at the end to transform the final flow model into an array
        # of lines to be rendered to the IG-XL flow sheet
        def format
          @lines = []
          @stack = { jobs: [], run_flags: [], flow_flags: [] }
          process(model.ast)
          lines
        end

        def on_test(node)
          lines << new_line(:test) do |line|
            process_all(node)
          end
        end

        def on_cz(node)
          setup, test = *node
          lines << new_line(:cz, cz_setup: setup) do |line|
            process_all(test)
          end
        end

        def on_group(node)
          debugger
        end

        def on_name(node)
          current_line.tname = node.to_a[0]
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
          current_line.result = 'None'
        end

        def on_set_run_flag(node)
          flag = node.to_a[0]
          if branch == :on_fail
            current_line.flag_fail = flag
          else
            current_line.flag_pass = flag
          end
        end

        def on_bin(node)
          if branch == :on_fail
            current_line.bin_fail = node.to_a[0]
          else
            current_line.bin_pass = node.to_a[0]
          end
        end

        def on_softbin(node)
          if branch == :on_fail
            current_line.sort_fail = node.to_a[0]
          else
            current_line.sort_pass = node.to_a[0]
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
                lines << new_line(:flag_true, parameter: or_flag)
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
              lines << new_line(:flag_true, parameter: and_flag)
              self.run_flag = [existing_flag[0], !existing_flag[1]]
              lines << new_line(:flag_false, parameter: and_flag)
              self.run_flag = [flag, !state]
              lines << new_line(:flag_false, parameter: and_flag)
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
            lines << new_line(:goto, parameter: label, enable: flag)
            process_all(node)
            lines << new_line(:nop, label: label)
          end
        end

        def on_log(node)
          lines << new_line(:logprint, parameter: node.to_a[0].gsub(' ', '_'))
        end

        def on_render(node)
          lines << node.to_a[0]
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

        # def add(type, options = {})
        #  ins = false
        #  options = save_context(options) if [:test, :cz].include?(type)
        #  branch_unless_enabled(options) do |options|
        #    ins = track_relationships(options) do |options|
        #      platform::FlowLine.new(type, options)
        #    end
        #    collection << ins unless Origen.interface.resources_mode?
        #    if ins.test?
        #      c = Origen.interface.consume_comments
        #      unless Origen.interface.resources_mode?
        #        Origen.interface.descriptions.add_for_test_usage(ins.parameter, Origen.interface.top_level_flow, c)
        #      end
        #    else
        #      Origen.interface.discard_comments
        #    end
        #  end
        #  ins
        # end

        # def logprint(message, options = {})
        #  message.gsub!(/\s/, '_')
        #  add(:logprint, options.merge(parameter: message))
        # end

        # def test(instance, options = {})
        #  add(:test, options.merge(parameter: instance))
        # end

        # def cz(instance, cz_setup, options = {})
        #  add(:cz, options.merge(parameter: instance, cz_setup: cz_setup))
        # end

        # def use_limit(name, options = {})
        #  add(:use_limit, options)
        # end

        # def goto(label, options = {})
        #  add(:goto, options.merge(parameter: label))
        # end

        # def nop(options = {})
        #  add(:nop, options.merge(parameter: nil))
        # end

        # def set_device(options = {})
        #  add(:set_device, options)
        # end

        # def set_error_bin(options = {})
        #  add(:set_error_bin, options)
        # end

        # def enable_flow_word(word, options = {})
        #  add(:enable_flow_word, options.merge(parameter: word))
        # end

        # def disable_flow_word(word, options = {})
        #  add(:disable_flow_word, options.merge(parameter: word))
        # end

        # def flag_false(name, options = {})
        #  add(:flag_false, options.merge(parameter: name))
        # end

        # def flag_false_all(name, options = {})
        #  add(:flag_false_all, options.merge(parameter: name))
        # end

        ##        def flag_true(name, options = {})
        # def flag_true(options = {})
        #  add(:flag_true, options)
        # end

        # def flag_true_all(name, options = {})
        #  add(:flag_true_all, options.merge(parameter: name))
        # end

        ## Generates 2 flow lines of flag-true to help set a single flag based on OR of 2 other flags
        # def or_flags(name1, name2, options = {})
        #  options = {
        #    condition: :fail, # condition to check for
        #    flowname:  false,  # if flowname provided
        #  }.merge(options)

        #  case options[:condition]
        #    when :fail
        #      options[:condition] = 'FAILED'
        #    when :pass
        #      options[:condition] = 'PASSED'
        #    else
        #      options[:condition] = 'RAN'
        #  end
        #  id = options.delete(:id)  # get original ID

        #  # set parameter names
        #  parameter = "#{id}"
        #  parameter += "_#{options[:flowname]}" if options[:flowname]
        #  parameter += "_#{options[:condition]}"

        #  options[:id] = id
        #  add(:flag_true_all, options.merge(parameter: parameter))
        #  options.delete(:id)
        #  add(:flag_false, options.merge(parameter: parameter, if_passed: name1, result: '', flag_pass: '', flag_fail: '')) # No ID
        #  add(:flag_false, options.merge(parameter: parameter, if_passed: name2)) # No ID
        #  nop
        # end

        ## All tests generated will not run unless the given enable word is asserted.
        ##
        ## This is specially implemented for J750 since it does not have a native
        ## support for flow word not enabled.
        ## It will generate a goto branch around the tests contained with the block
        ## if the given flow word is enabled.
        # def unless_enable(word, options = {})
        #  if options[:or]
        #    yield
        #  else
        #    @unless_enable_block = word
        #    options = options.merge(unless_enable: word)
        #    branch_unless_enabled(options.merge(_force_unless_enable: true)) do
        #      yield
        #    end
        #   @unless_enable_block = nil
        #  end
        # end
        # alias_method :unless_enabled, :unless_enable

        # def start_flow_branch(identifier, options = {})
        #  goto(identifier, options)
        # end

        # def skip(identifier = nil, options = {})
        #  identifier, options = nil, identifier if identifier.is_a?(Hash)
        #  identifier = generate_unique_label(identifier)
        #  goto(identifier, options)
        #  yield
        #  nop(label: identifier)
        # end

        # private
      end
    end
  end
end
