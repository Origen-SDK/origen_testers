module OrigenTesters
  # Provides a common API to add tests to a flow that is supported by all testers.
  #
  # This builds up a flow model using the Abstract Test Program (ATP) gem, which
  # now deals with implementing the flow control API.
  #
  # Individual tester drivers in this plugin are then responsible at the end to
  # render the abstract flow to their specific format and conventions.
  module Flow
    include OrigenTesters::Generator

    PROGRAM_MODELS_DIR = "#{Origen.root}/tmp/program_models"

    def self.callstack
      @callstack ||= []
    end

    def self.comment_stack
      @comment_stack ||= []
    end

    def lines
      @lines
    end

    # Returns the abstract test program model, this is shared by all
    # flow created together in a generation run
    def program
      @@program ||= ATP::Program.new
    end

    def save_program
      FileUtils.mkdir_p(PROGRAM_MODELS_DIR) unless File.exist?(PROGRAM_MODELS_DIR)
      program.save("#{PROGRAM_MODELS_DIR}/#{Origen.target.name}")
    end

    def model
      if Origen.interface.resources_mode?
        @throwaway ||= ATP::Flow.new(self)
      else
        @model ||= program.flow(id)
      end
    end

    def enable(var, options = {})
      add_meta!(options)
      model.enable(var, clean_options(options))
    end

    def disable(var, options = {})
      add_meta!(options)
      model.disable(var, clean_options(options))
    end

    def bin(number, options = {})
      if number.is_a?(Hash)
        fail 'The bin number must be passed as the first argument'
      end
      add_meta!(options)
      options[:type] ||= :fail
      model.bin(number, clean_options(options))
    end

    def pass(number, options = {})
      if number.is_a?(Hash)
        fail 'The bin number must be passed as the first argument'
      end
      options[:type] = :pass
      bin(number, clean_options(options))
    end

    def test(instance, options = {})
      add_meta_and_description!(options)
      model.test(instance, clean_options(options))
    end

    def render(file, options = {})
      add_meta!(options)
      begin
        text = super
      rescue
        text = file
      end
      model.render(text)
    end

    def cz(instance, cz_setup, options = {})
      add_meta_and_description!(options)
      model.cz(instance, cz_setup, clean_options(options))
    end
    alias_method :characterize, :cz

    def log(message, options = {})
      add_meta!(options)
      model.log(message, clean_options(options))
    end
    alias_method :logprint, :log

    def group(name, options = {})
      add_meta!(options)
      model.group(name, clean_options(options)) do
        yield
      end
    end

    def nop(options = {})
    end

    # @api private
    # This fires between target loads
    def at_run_start
      @@program = nil
    end

    def if_job(*jobs)
      options = jobs.last.is_a?(Hash) ? jobs.pop : {}
      options[:if_job] = jobs.flatten
      add_meta!(options)
      model.with_conditions(options) do
        yield
      end
    end
    alias_method :if_jobs, :if_job

    def unless_job(*jobs)
      options = jobs.last.is_a?(Hash) ? jobs.pop : {}
      options[:unless_job] = jobs.flatten
      add_meta!(options)
      model.with_conditions(options) do
        yield
      end
    end
    alias_method :unless_jobs, :unless_job

    def if_enable(word, options = {})
      if options[:or]
        yield
      else
        options = { enable: word }
        add_meta!(options)
        model.with_conditions(options) do
          yield
        end
      end
    end
    alias_method :if_enabled, :if_enable

    def unless_enable(word, options = {})
      if options[:or]
        yield
      else
        options = { unless_enable: word }
        add_meta!(options)
        model.with_conditions(options) do
          yield
        end
      end
    end
    alias_method :unless_enabled, :unless_enable

    def if_passed(test_id, options = {})
      if test_id.is_a?(Array)
        fail 'if_passed only accepts one ID, use if_any_passed or if_all_passed for multiple IDs'
      end
      options = { if_passed: test_id }
      add_meta!(options)
      model.with_conditions(options) do
        yield
      end
    end
    alias_method :unless_failed, :if_passed

    def if_failed(test_id, options = {})
      if test_id.is_a?(Array)
        fail 'if_failed only accepts one ID, use if_any_failed or if_all_failed for multiple IDs'
      end
      options = { if_failed: test_id }
      add_meta!(options)
      model.with_conditions(options) do
        yield
      end
    end
    alias_method :unless_passed, :if_failed

    def if_ran(test_id, options = {})
      options = { if_ran: test_id }
      add_meta!(options)
      model.with_conditions(options) do
        yield
      end
    end

    def unless_ran(test_id, options = {})
      options = { unless_ran: test_id }
      add_meta!(options)
      model.with_conditions(options) do
        yield
      end
    end

    def if_any_failed(*ids)
      options = ids.last.is_a?(Hash) ? ids.pop : {}
      options[:if_any_failed] = ids.flatten
      add_meta!(options)
      model.with_conditions(options) do
        yield
      end
    end

    def if_all_failed(*ids)
      options = ids.last.is_a?(Hash) ? ids.pop : {}
      options[:if_all_failed] = ids.flatten
      add_meta!(options)
      model.with_conditions(options) do
        yield
      end
    end

    def if_any_passed(*ids)
      options = ids.last.is_a?(Hash) ? ids.pop : {}
      options[:if_any_passed] = ids.flatten
      add_meta!(options)
      model.with_conditions(options) do
        yield
      end
    end

    def if_all_passed(*ids)
      options = ids.last.is_a?(Hash) ? ids.pop : {}
      options[:if_all_passed] = ids.flatten
      add_meta!(options)
      model.with_conditions(options) do
        yield
      end
    end

    # @api private
    def is_the_flow?
      true
    end

    # Returns true if the test context generated from the supplied options + existing condition
    # wrappers is different from that which was applied to the previous test.
    def context_changed?(options)
      options = clean_options(options)
      model.context_changed?(options)
    end

    def generate_unique_label(id = nil)
      id = 'label' if !id || id == ''
      label = "#{Origen.interface.app_identifier}_#{id}"
      label.gsub!(' ', '_')
      label.upcase!
      @@labels ||= {}
      @@labels[Origen.tester.class] ||= {}
      @@labels[Origen.tester.class][label] ||= 0
      @@labels[Origen.tester.class][label] += 1
      "#{label}_#{@@labels[Origen.tester.class][label]}"
    end

    private

    def add_meta!(options)
      flow_file = OrigenTesters::Flow.callstack.last
      called_from = caller.find { |l| l =~ /^#{flow_file}:.*/ }
      if called_from
        called_from = called_from.split(':')
        options[:source_file] = called_from[0]
        options[:source_line_number] = called_from[1].to_i
      end
    end

    def add_meta_and_description!(options)
      add_meta!(options)
      comments = OrigenTesters::Flow.comment_stack.last
      if options[:source_line_number]
        while comments.first && comments.first.first < options[:source_line_number]
          options[:description] ||= []
          options[:description] += comments.shift[1]
        end
      end
    end

    def clean_options(options)
      ATP::AST::Builder::CONDITION_KEYS.each do |key|
        if v = options.delete(key)
          options[:conditions] ||= {}
          if options[:conditions][key]
            fail "Multiple values assigned to flow condition #{key}"
          else
            options[:conditions][key] = v
          end
        end
      end
      options
    end
  end
end
