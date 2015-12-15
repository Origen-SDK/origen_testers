module OrigenTesters
  module IGXLBasedTester
    class Base
      class Flow < ATP::Formatter
        include OrigenTesters::Flow

        OUTPUT_POSTFIX = 'flow'

        attr_reader :current_line
        attr_reader :branch
        attr_reader :stack

        # Will be called at the end to transform the final flow model into an array
        # of lines to be rendered to the IG-XL flow sheet
        def format
          @lines = []
          @stack = { jobs: [] }
          process(model.ast)
          lines
        end

        def on_test(node)
          lines << new_line(:test, job: stack[:jobs].last) do
            process_all(node)
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
          if branch == :on_fail
            current_line.result = 'None'
          end
        end

        def on_set_run_flag(node)
          if branch == :on_fail
            current_line.flag_fail = node.to_a[0].sub(/failed$/, 'FAILED')
          end
        end

        def on_on_fail(node)
          @branch = :on_fail
          process_all(node)
          @branch = nil
        end

        def on_job(node)
          job = clean_job(node.to_a[0])
          stack[:jobs] << [stack[:jobs].last, job].compact.join(',')
          process_all(node)
          stack[:jobs].pop
        end

        def on_log(node)
          lines << new_line(:logprint, parameter: node.to_a[0].gsub(' ', '_'))
        end

        def on_render(node)
          lines << node.to_a[0]
        end

        def new_line(type, attrs = {})
          line = platform::FlowLine.new(type, attrs)
          @current_line = line
          yield line if block_given?
          @current_line = nil
          line
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

        ## If the test has an unless_enable then branch around it
        # def branch_unless_enabled(options)
        #  word = options.delete(:unless_enable) || options.delete(:unless_enabled)
        #  if word && (word != @unless_enable_block || options.delete(:_force_unless_enable))
        #    # Not sure if this is really required, but duplicating these hashes here to ensure
        #    # that all other flow context keys are preserved and applied to the branch lines
        #    orig_options = options.merge({})
        #    close_options = options.merge({})
        #    label = generate_unique_label
        #    goto(label, options.merge(if_enable: word))
        #    yield orig_options
        #    nop(close_options.merge(label: label))
        #  else
        #    yield options
        #  end
        # end
      end
    end
  end
end
