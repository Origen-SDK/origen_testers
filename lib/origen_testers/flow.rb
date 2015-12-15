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
      @model ||= program.flow(id)
    end

    def test(instance, options = {})
      model.test(instance, clean_options(options))
    end

    def render(file, options = {})
      model.render(super)
    end

    def cz(instance, cz_setup, options = {})
    end

    def log(message, options = {})
      model.log(message, options)
    end
    alias_method :logprint, :log

    def skip(identifier = nil, options = {})
      yield
    end

    def nop(options = {})
    end

    def or_flags(name1, name2, options = {})
    end

    def at_run_start
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
      yield word
    end
    alias_method :if_enabled, :if_enable

    def unless_enable(word, options = {})
      yield word
    end
    alias_method :unless_enabled, :unless_enable

    def if_passed(test_id, options = {})
      yield
    end
    alias_method :unless_failed, :if_passed

    def if_failed(test_id, options = {})
      yield
    end
    alias_method :unless_passed, :if_failed

    def if_ran(test_id, options = {})
      yield
    end

    def unless_ran(test_id, options = {})
      yield
    end

    def if_all_passed(test_id, options = {})
      yield
    end
    alias_method :unless_any_failed, :if_all_passed

    def if_any_passed(test_id, options = {})
      yield
    end
    alias_method :unless_all_failed, :if_any_passed

    def if_all_failed(test_id, options = {})
      yield
    end
    alias_method :unless_any_passed, :if_all_failed

    def if_any_failed(test_id, options = {})
      yield
    end
    alias_method :unless_all_passed, :if_any_failed

    def is_the_flow?
      true
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
