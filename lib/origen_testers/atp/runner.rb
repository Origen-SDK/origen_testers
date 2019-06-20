module OrigenTesters::ATP
  # This class is responsible for executing the given test flow based on a given
  # set of runtime conditions.
  # A subset of the input AST will be returned containing only the nodes that would
  # be hit when the flow is executed under the given conditions.
  class Runner < Processor
    def run(node, options = {})
      options = {
        evaluate_enables:    true,
        evaluate_flags:      true,
        evaluate_set_result: true
      }.merge(options)
      @options = options
      @completed = false
      @groups = []
      @groups_on_fail = []
      @groups_on_pass = []
      node = Processors::AddIDs.new.run(node)
      node = Processors::AddSetResult.new.run(node)
      process(node)
    end

    def on_flow(node)
      c = open_container do
        process_all(node.children)
      end
      node.updated(nil, c)
    end

    def on_name(node)
      container << node
    end

    def on_if_flag(node)
      if @options[:evaluate_flags]
        flag, *nodes = *node
        flag = [flag].flatten
        enabled = node.type == :if_flag
        active = flag.any? { |f| set_flags.include?(f) }
        if (enabled && active) || (!enabled && !active)
          process_all(nodes)
        end
      else
        c = open_container do
          process_all(node.children)
        end
        container << node.updated(nil, node.children.take(1) + c)
      end
    end
    alias_method :on_unless_flag, :on_if_flag

    def on_if_enabled(node)
      if @options[:evaluate_enables]
        flag, *nodes = *node
        flag = [flag].flatten
        enabled = node.type == :if_enabled
        active = flag.any? { |f| set_enables.include?(f) }
        if (enabled && active) || (!enabled && !active)
          process_all(nodes)
        end
      else
        c = open_container do
          process_all(node.children)
        end
        container << node.updated(nil, node.children.take(1) + c)
      end
    end
    alias_method :on_unless_enabled, :on_if_enabled

    def on_if_failed(node)
      id, *nodes = *node
      if failed_test_ids.include?(id)
        process_all(nodes)
      end
    end

    def on_if_passed(node)
      id, *nodes = *node
      unless failed_test_ids.include?(id)
        process_all(nodes)
      end
    end

    def on_test(node)
      if id = node.find(:id)
        id = id.to_a[0]
        if failed_test_ids.include?(id)
          node = node.add(node.updated(:failed, []))
          failed = true
          if n_on_fail = node.find(:on_fail)
            node = node.remove(n_on_fail)
          end
        end
      end
      unless failed
        if n_on_pass = node.find(:on_pass)
          node = node.remove(n_on_pass)
        end
      end

      unless completed?
        container << node
        process_all(n_on_fail) if n_on_fail
        process_all(n_on_pass) if n_on_pass
      end

      if failed
        # Give indication to the parent group that at least one test within it failed
        if @groups.last
          @groups.pop
          @groups << false
        end
        if n = node.find(:on_fail)
          # If it has been set by a parent group, don't clear it
          orig = @continue
          @continue ||= !!n.find(:continue)
          process_all(n)
          @continue = orig
        end
      else
        if n = node.find(:on_pass)
          process_all(n)
        end
      end
    end

    def on_group(node)
      on_fail = node.find(:on_fail)
      on_pass = node.find(:on_pass)
      c = open_container do
        @groups << true  # This will be set to false by any tests that fail within the group
        @groups_on_fail << on_fail
        @groups_on_pass << on_pass
        if on_fail
          orig = @continue
          @continue = !!on_fail.find(:continue)
          process_all(node.children - [on_fail, on_pass])
          @continue = orig
        else
          process_all(node.children - [on_fail, on_pass])
        end
        if !@groups.pop # If failed
          if on_fail
            @continue = !!on_fail.find(:continue)
            process_all(on_fail)
            @continue = false
          end
        else
          if on_pass
            process_all(on_pass)
          end
        end
        @groups_on_fail.pop
        @groups_on_pass.pop
      end
      container << node.updated(nil, c)
    end

    def on_set_result(node)
      unless @continue
        container << node unless completed?
        @completed = true if @options[:evaluate_set_result]
      end
    end

    def on_set_flag(node)
      set_flags << node.to_a[0]
    end

    def on_enable(node)
      set_enables << node.value unless set_enables.include?(node.value)
    end

    def on_disable(node)
      set_enables.delete(node.value)
    end

    def on_log(node)
      container << node unless completed?
    end
    alias_method :on_render, :on_log

    def on_if_job(node)
      jobs, *nodes = *node
      jobs = clean_job(jobs)
      state = node.type == :if_job
      unless job
        fail 'Flow contains JOB-based conditions and no current JOB has been given!'
      end
      if state
        process_all(node) if jobs.include?(job)
      else
        process_all(node) unless jobs.include?(job)
      end
    end
    alias_method :on_unless_job, :on_if_job

    def clean_job(job)
      [job].flatten.map { |j| j.to_s.upcase }
    end

    def job
      @options[:job].to_s.upcase if @options[:job]
    end

    def failed_test_ids
      @failed_test_ids ||= [@options[:failed_test_id] || @options[:failed_test_ids]].flatten.compact
    end

    def set_flags
      @set_flags ||= []
    end

    # Returns an array of enabled flow flags
    def set_enables
      @set_enables ||= [@options[:enable] || @options[:enables]].flatten.compact
    end

    def completed?
      @completed
    end

    def open_container(c = [])
      @containers ||= []
      @containers << c
      yield
      @containers.pop
    end

    def container
      @containers.last
    end
  end
end
