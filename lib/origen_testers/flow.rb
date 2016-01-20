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

    def lines
      @lines
    end

    # Returns the abstract test program model, this is shared by all
    # flow created together in a generation run
    def program
      @@program ||= ATP::Program.new
    end

    def model
      if Origen.interface.resources_mode?
        @throwaway ||= ATP::Flow.new(self)
      else
        @model ||= program.flow(id)
      end
    end

    def fail(number, options = {})
      options[:type] ||= :fail
      model.bin(number, options)
    end
    alias_method :bin, :fail

    def pass(number, options = {})
      options[:type] = :pass
      bin(number, options)
    end

    def test(instance, options = {})
      model.test(instance, clean_options(options))
    end

    def render(file, options = {})
      model.render(super)
    end

    def cz(instance, cz_setup, options = {})
      model.cz(instance, cz_setup, clean_options(options))
    end
    alias_method :characterize, :cz

    def log(message, options = {})
      model.log(message, options)
    end
    alias_method :logprint, :log

    def group(name, options = {})
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
      model.with_conditions(job: ATP.or(jobs.flatten)) do
        yield
      end
    end
    alias_method :if_jobs, :if_job

    def unless_job(*jobs)
      model.with_conditions(unless_job: ATP.or(jobs.flatten)) do
        yield
      end
    end
    alias_method :unless_jobs, :unless_job

    def if_enable(word, options = {})
      model.with_conditions(enable: word) do
        yield
      end
    end
    alias_method :if_enabled, :if_enable

    def unless_enable(word, options = {})
      model.with_conditions(unless_enable: word) do
        yield
      end
    end
    alias_method :unless_enabled, :unless_enable

    def if_passed(test_id, options = {})
      if test_id.is_a?(Array)
        fail 'if_passed only accepts one ID, use if_any_passed or if_all_passed for multiple IDs'
      end
      model.with_conditions(if_passed: test_id) do
        yield
      end
    end
    alias_method :unless_failed, :if_passed

    def if_failed(test_id, options = {})
      if test_id.is_a?(Array)
        fail 'if_failed only accepts one ID, use if_any_failed or if_all_failed for multiple IDs'
      end
      model.with_conditions(if_failed: test_id) do
        yield
      end
    end
    alias_method :unless_passed, :if_failed

    def if_ran(test_id, options = {})
      model.with_conditions(if_ran: test_id) do
        yield
      end
    end

    def unless_ran(test_id, options = {})
      model.with_conditions(unless_ran: test_id) do
        yield
      end
    end

    def if_any_failed(*ids)
      options = ids.pop if ids.last.is_a?(Hash)
      model.with_conditions(if_any_failed: ids.flatten) do
        yield
      end
    end

    def if_all_failed(*ids)
      options = ids.pop if ids.last.is_a?(Hash)
      model.with_conditions(if_all_failed: ids.flatten) do
        yield
      end
    end

    def if_any_passed(*ids)
      options = ids.pop if ids.last.is_a?(Hash)
      model.with_conditions(if_any_passed: ids.flatten) do
        yield
      end
    end

    def if_all_passed(*ids)
      options = ids.pop if ids.last.is_a?(Hash)
      model.with_conditions(if_all_passed: ids.flatten) do
        yield
      end
    end

    # @api private
    def is_the_flow?
      true
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
