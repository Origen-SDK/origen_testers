module OrigenTesters::ATP
  # Implements the main user API for building and interacting
  # with an abstract test program
  class Flow
    attr_reader :program, :name

    CONDITION_KEYS = {
      if_enabled:              :if_enabled,
      if_enable:               :if_enabled,
      enabled:                 :if_enabled,
      enable_flag:             :if_enabled,
      enable:                  :if_enabled,

      unless_enabled:          :unless_enabled,
      not_enabled:             :unless_enabled,
      disabled:                :unless_enabled,
      disable:                 :unless_enabled,
      unless_enable:           :unless_enabled,

      if_failed:               :if_failed,
      unless_passed:           :if_failed,
      failed:                  :if_failed,

      if_passed:               :if_passed,
      unless_failed:           :if_passed,
      passed:                  :if_passed,

      if_any_failed:           :if_any_failed,
      unless_all_passed:       :if_any_failed,

      if_all_failed:           :if_all_failed,
      unless_any_passed:       :if_all_failed,

      if_any_passed:           :if_any_passed,
      unless_all_failed:       :if_any_passed,

      if_all_passed:           :if_all_passed,
      unless_any_failed:       :if_all_passed,

      if_ran:                  :if_ran,
      if_executed:             :if_ran,

      unless_ran:              :unless_ran,
      unless_executed:         :unless_ran,

      job:                     :if_job,
      jobs:                    :if_job,
      if_job:                  :if_job,
      if_jobs:                 :if_job,

      unless_job:              :unless_job,
      unless_jobs:             :unless_job,

      if_flag:                 :if_flag,

      unless_flag:             :unless_flag,

      whenever:                :whenever,
      whenever_all:            :whenever_all,
      whenever_any:            :whenever_any,

      group:                   :group,

      if_any_site_failed:      :if_any_sites_failed,
      if_any_sites_failed:     :if_any_sites_failed,
      unless_all_sites_passed: :if_any_sites_failed,

      if_all_sites_failed:     :if_all_sites_failed,
      unless_any_sites_passed: :if_all_sites_failed,
      unless_any_site_passed:  :if_all_sites_failed,

      if_any_site_passed:      :if_any_sites_passed,
      if_any_sites_passed:     :if_any_sites_passed,
      unless_all_sites_failed: :if_any_sites_passed,

      if_all_sites_passed:     :if_all_sites_passed,
      unless_any_sites_failed: :if_all_sites_passed,
      unless_any_site_failed:  :if_all_sites_passed
    }

    CONDITION_NODE_TYPES = CONDITION_KEYS.values.uniq

    RELATIONAL_OPERATORS = [:eq, :ne, :lt, :le, :gt, :ge]

    def initialize(program, name = nil, options = {})
      name, options = nil, name if name.is_a?(Hash)
      @source_file = []
      @source_line_number = []
      @description = []
      @program = program
      @name = name
      extract_meta!(options) do
        @pipeline = [n1(:flow, n1(:name, name))]
      end
    end

    # @api private
    def marshal_dump
      [@name, @program, Processors::Marshal.new.process(raw)]
    end

    # @api private
    def marshal_load(array)
      @name, @program, raw = array
      @pipeline = [raw]
    end

    # Returns the raw AST
    def raw
      n = nil
      @pipeline.reverse_each do |node|
        if n
          n = node.updated(nil, node.children + [n])
        else
          n = node
        end
      end
      n
    end

    # Returns a processed/optimized AST, this is the one that should be
    # used to build and represent the given test flow
    def ast(options = {})
      options = {
        apply_relationships:          true,
        # Supply a unique ID to append to all IDs
        unique_id:                    nil,
        # Set to :smt, or :igxl
        optimization:                 :runner,
        # When true, will remove set_result nodes in an on_fail branch which contains a continue
        implement_continue:           true,
        # When false, this will not optimize the use of a flag by nesting a dependent test within
        # the parent test's on_fail branch if the on_fail contains a continue
        optimize_flags_when_continue: true,
        # These options are not intended for application use, but provide the ability to
        # turn off certain processors during test cases
        add_ids:                      true,
        optimize_flags:               true,
        one_flag_per_test:            true,
        include_sub_flows:            true
      }.merge(options)
      ###############################################################################
      ## Common pre-processing and validation
      ###############################################################################
      ast = Processors::PreCleaner.new.run(raw)
      Validators::DuplicateIDs.new(self).run(ast)
      Validators::MissingIDs.new(self).run(ast)
      Validators::Jobs.new(self).run(ast)
      Validators::Flags.new(self).run(ast)
      # Ensure everything has an ID, this helps later if condition nodes need to be generated
      ast = Processors::AddIDs.new.run(ast) if options[:add_ids]
      ast = Processors::FlowID.new.run(ast, options[:unique_id]) if options[:unique_id]
      ast = Processors::SubFlowRemover.new.run(ast) unless options[:include_sub_flows]

      ###############################################################################
      ## Optimization for a C-like flow target, e.g. V93K
      ###############################################################################
      if options[:optimization] == :smt || options[:optimization] == :runner
        # This applies all the relationships by setting flags in the referenced test and
        # changing all if_passed/failed type nodes to if_flag type nodes
        ast = Processors::Relationship.new.run(ast) if options[:apply_relationships]
        ast = Processors::Condition.new.run(ast)
        unless options[:optimization] == :runner
          ast = Processors::ContinueImplementer.new.run(ast) if options[:implement_continue]
        end
        if options[:optimize_flags]
          ast = Processors::FlagOptimizer.new.run(ast, optimize_when_continue: options[:optimize_flags_when_continue])
        end
        ast = Processors::AdjacentIfCombiner.new.run(ast)

      ###############################################################################
      ## Optimization for a row-based target, e.g. UltraFLEX
      ###############################################################################
      elsif options[:optimization] == :igxl
        # Un-nest everything embedded in else nodes
        ast = Processors::ElseRemover.new.run(ast)
        # Un-nest everything embedded in on_pass/fail nodes except for binning and
        # flag setting
        ast = Processors::OnPassFailRemover.new.run(ast)
        # This applies all the relationships by setting flags in the referenced test and
        # changing all if_passed/failed type nodes to if_flag type nodes
        ast = Processors::Relationship.new.run(ast) if options[:apply_relationships]
        ast = Processors::Condition.new.run(ast)
        ast = Processors::ApplyPostGroupActions.new.run(ast)
        ast = Processors::OneFlagPerTest.new.run(ast) if options[:one_flag_per_test]
        ast = Processors::RedundantConditionRemover.new.run(ast)

      ###############################################################################
      ## Not currently used, more of a test case
      ###############################################################################
      elsif options[:optimization] == :flat
        # Un-nest everything embedded in else nodes
        ast = Processors::ElseRemover.new.run(ast)
        # Un-nest everything embedded in on_pass/fail nodes except for binning and
        # flag setting
        ast = Processors::OnPassFailRemover.new.run(ast)
        ast = Processors::Condition.new.run(ast)
        ast = Processors::Flattener.new.run(ast)

      ###############################################################################
      ## Default Optimization
      ###############################################################################
      else
        ast = Processors::Condition.new.run(ast)
      end

      ###############################################################################
      ## Common cleanup
      ###############################################################################
      # Removes any empty on_pass and on_fail branches
      ast = Processors::EmptyBranchRemover.new.run(ast)
      ast
    end

    # Indicate the that given flags should be considered volatile (can change at any time), which will
    # prevent them from been touched by the optimization algorithms
    def volatile(*flags)
      options = flags.pop if flags.last.is_a?(Hash)
      flags = flags.flatten
      @pipeline[0] = add_volatile_flags(@pipeline[0], flags)
    end

    # Indicate the that given flags should keep state between units 
    # prevent them from being in the initialization block
    # these flags will be the user's responsibility to initialize
    def global(*flags)
      options = flags.pop if flags.last.is_a?(Hash)
      flags = flags.flatten
      @pipeline[0] = add_global_flags(@pipeline[0], flags)
    end

    # Record a description for a bin number
    def describe_bin(number, description, options = {})
      @pipeline[0] = add_bin_description(@pipeline[0], number, description, type: :hard)
    end

    # Record a description for a softbin number
    def describe_soft_bin(number, description, options = {})
      @pipeline[0] = add_bin_description(@pipeline[0], number, description, type: :soft)
    end
    alias_method :describe_softbin, :describe_soft_bin

    # Group all tests generated within the given block
    #
    # @example
    #   flow.group "RAM Tests" do
    #     flow.test ...
    #     flow.test ...
    #   end
    def group(name, options = {}, &block)
      # The idiomatic way of creating a group in SMT8 is a sub-flow
      if tester.try(:smt8?)
        extract_meta!(options) do
          apply_conditions(options) do
            parent, sub_flow = *::Flow._sub_flow(name, options, &block)
            path = sub_flow.output_file.relative_path_from(Origen.file_handler.output_directory)
            ast = sub_flow.atp.raw
            name, *children = *ast
            nodes = [name]
            nodes << id(options[:id]) if options[:id]
            nodes << n1(:path, path.to_s)
            nodes += children
            ast = ast.updated :sub_flow, nodes,
                              file:        options.delete(:source_file) || source_file,
                              line_number: options.delete(:source_line_number) || source_line_number,
                              description: options.delete(:description) || description
            ast
          end
        end
      else
        extract_meta!(options) do
          apply_conditions(options) do
            children = [n1(:name, name)]
            children << n1(:bypass, options[:bypass]) if options[:bypass]
            if options[:comment] || options[:description] || options[:desc]
              children << n1(:comment, options[:comment] || options[:description] || options[:desc])
            end
            children << id(options[:id]) if options[:id]
            children << on_fail(options[:on_fail]) if options[:on_fail]
            children << on_pass(options[:on_pass]) if options[:on_pass]
            g = n(:group, children)
            append_to(g) { yield }
          end
        end
      end
    end

    # Add a test line to the flow
    #
    # @param [String, Symbol] the name of the test
    # @param [Hash] options a hash to describe the test's attributes
    # @option options [Symbol] :id A unique test ID
    # @option options [String] :description A description of what the test does, usually formatted in markdown
    # @option options [Hash] :on_fail What action to take if the test fails, e.g. assign a bin
    # @option options [Hash] :on_pass What action to take if the test passes
    # @option options [Hash] :conditions What conditions must be met to execute the test
    def test(instance, options = {})
      extract_meta!(options) do
        apply_conditions(options) do
          if options[:on_fail].is_a?(Proc)
            before_on_fail = options.delete(:on_fail)
          end
          if options[:on_pass].is_a?(Proc)
            before_on_pass = options.delete(:on_pass)
          end
          # Allows any continue, bin, or soft bin argument passed in at the options top-level to be assumed
          # to be the action to take if the test fails
          if b = options.delete(:bin)
            options[:on_fail] ||= {}
            options[:on_fail][:bin] = b
          end
          if b = options.delete(:bin_description)
            options[:on_fail] ||= {}
            options[:on_fail][:bin_description] = b
          end
          if b = options.delete(:bin_attrs)
            options[:on_fail] ||= {}
            options[:on_fail][:bin_attrs] = b
          end
          if b = options.delete(:softbin) || b = options.delete(:sbin) || b = options.delete(:soft_bin)
            options[:on_fail] ||= {}
            options[:on_fail][:softbin] = b
          end
          if b = options.delete(:softbin_description) || options.delete(:sbin_description) || options.delete(:soft_bin_description)
            options[:on_fail] ||= {}
            options[:on_fail][:softbin_description] = b
          end
          if options.delete(:continue)
            options[:on_fail] ||= {}
            options[:on_fail][:continue] = true
          end
          if options.key?(:delayed)
            options[:on_fail] ||= {}
            options[:on_fail][:delayed] = options.delete(:delayed)
          end
          if f = options.delete(:flag_pass)
            options[:on_pass] ||= {}
            options[:on_pass][:set_flag] = f
          end
          if f = options.delete(:flag_fail)
            options[:on_fail] ||= {}
            options[:on_fail][:set_flag] = f
          end

          children = [n1(:object, instance)]

          name = (options[:name] || options[:tname] || options[:test_name])
          unless name
            # Starting in Ruby3 type Symbol responds to name
            unless instance.is_a?(Symbol)
              [:name, :tname, :test_name].each do |m|
                name ||= instance.respond_to?(m) ? instance.send(m) : nil
              end
            end
          end
          children << n1(:name, name) if name

          num = (options[:number] || options[:num] || options[:tnum] || options[:test_number])
          unless num
            [:number, :num, :tnum, :test_number].each do |m|
              num ||= instance.respond_to?(m) ? instance.send(m) : nil
            end
          end
          children << number(num) if num

          children << id(options[:id]) if options[:id]

          if levels = options[:level] || options[:levels]
            levels = [levels] unless levels.is_a?(Array)
            levels.each do |l|
              children << level(l[:name], l[:value], l[:unit] || l[:units])
            end
          end

          lims = options[:limit] || options[:limits]
          if lims || options[:lo] || options[:low] || options[:hi] || options[:high]
            if lims == :none || lims == 'none'
              children << n0(:nolimits)
            else
              lims = Array(lims) unless lims.is_a?(Array)
              if lo = options[:lo] || options[:low]
                lims << { value: lo, rule: :gte }
              end
              if hi = options[:hi] || options[:high]
                lims << { value: hi, rule: :lte }
              end
              lims.each do |l|
                if l.is_a?(Hash)
                  children << n(:limit, [l[:value], l[:rule], l[:unit] || l[:units], l[:selector]])
                end
              end
            end
          end

          if pins = options[:pin] || options[:pins]
            pins = [pins] unless pins.is_a?(Array)
            pins.each do |p|
              if p.is_a?(Hash)
                children << pin(p[:name])
              else
                children << pin(p)
              end
            end
          end

          if pats = options[:pattern] || options[:patterns]
            pats = [pats] unless pats.is_a?(Array)
            pats.each do |p|
              if p.is_a?(Hash)
                children << pattern(p[:name], p[:path])
              else
                children << pattern(p)
              end
            end
          end

          if options[:meta]
            attrs = []
            options[:meta].each { |k, v| attrs << attribute(k, v) }
            children << n(:meta, attrs)
          end

          if options[:test_text]
            children << n(:test_text, [options[:test_text]])
          end

          if subs = options[:sub_test] || options[:sub_tests]
            subs = [subs] unless subs.is_a?(Array)
            subs.each do |s|
              children << s.updated(:sub_test, nil)
            end
          end

          if before_on_fail
            on_fail_node = on_fail(before_on_fail)
            if options[:on_fail]
              on_fail_node = on_fail_node.updated(nil, on_fail_node.children + on_fail(options[:on_fail]).children)
            end
            children << on_fail_node
          else
            children << on_fail(options[:on_fail]) if options[:on_fail]
          end

          if before_on_pass
            on_pass_node = on_pass(before_on_pass)
            if options[:on_pass]
              on_pass_node = on_pass_node.updated(nil, on_pass_node.children + on_pass(options[:on_pass]).children)
            end
            children << on_pass_node
          else
            children << on_pass(options[:on_pass]) if options[:on_pass]
          end

          children << priority(options[:priority]) if options[:priority]

          save_conditions
          n(:test, children)
        end
      end
    end

    # Equivalent to calling test, but returns a sub_test node instead of adding it to the flow.
    #
    # This is a helper to create sub_tests for inclusion in a top-level test node.
    def sub_test(instance, options = {})
      temp = append_to(n0(:temp)) { test(instance, options) }
      temp.children.first.updated(:sub_test, nil)
    end

    def sub_flow(flow_node, options = {})
      name, *children = *flow_node
      if options[:path]
        children = [name] + [n1(:path, options[:path])] + children
      else
        children = [name] + children
      end
      apply_conditions(options) do
        flow_node.updated(:sub_flow, children)
      end
    end

    def bin(number, options = {})
      if number.is_a?(Hash)
        fail 'The bin number must be passed as the first argument'
      end
      options[:bin_description] ||= options.delete(:description)
      extract_meta!(options) do
        apply_conditions(options) do
          options[:type] ||= :fail
          options[:bin] = number
          options[:softbin] ||= options[:soft_bin] || options[:sbin]
          set_result(options[:type], options)
        end
      end
    end

    def pass(number, options = {})
      if number.is_a?(Hash)
        fail 'The bin number must be passed as the first argument'
      end
      options[:type] = :pass
      bin(number, options)
    end

    def cz(instance, cz_setup, options = {})
      extract_meta!(options) do
        apply_conditions(options) do
          node = n1(:cz, cz_setup)
          append_to(node) { test(instance, options) }
        end
      end
    end
    alias_method :characterize, :cz

    # Append a log message line to the flow
    def log(message, options = {})
      extract_meta!(options) do
        apply_conditions(options) do
          n1(:log, message.to_s)
        end
      end
    end

    # Enable a flow control variable
    def enable(var, options = {})
      extract_meta!(options) do
        apply_conditions(options) do
          n1(:enable, var)
        end
      end
    end

    # Disable a flow control variable
    def disable(var, options = {})
      extract_meta!(options) do
        apply_conditions(options) do
          n1(:disable, var)
        end
      end
    end

    def set_flag(flag, options = {})
      extract_meta!(options) do
        apply_conditions(options) do
          set_flag_node(flag)
        end
      end
    end

    def set(var, val, options = {})
      extract_meta!(options) do
        apply_conditions(options) do
          n2(:set, var, val)
        end
      end
    end

    # Insert explicitly rendered content in to the flow
    def render(str, options = {})
      extract_meta!(options) do
        apply_conditions(options) do
          n1(:render, str)
        end
      end
    end

    def continue(options = {})
      extract_meta!(options) do
        apply_conditions(options) do
          n0(:continue)
        end
      end
    end

    # Execute the given flow in the console
    def run(options = {})
      Formatters::Datalog.run_and_format(ast, options)
      nil
    end

    # Returns true if the test context generated from the supplied options + existing condition
    # wrappers, is different from that which was applied to the previous test.
    def context_changed?(options)
      options[:_dont_delete_conditions_] = true
      last_conditions != clean_conditions(open_conditions + [extract_conditions(options)])
    end

    def whenever(*expressions, &block)
      if expressions.last.is_a?(Hash)
        options = expressions.pop
      else
        options = {}
      end
      flow_control_method(:whenever, expressions, options, &block)
    end

    def loop(*args, &block)
      unless args[0].keys.include?(:from) && args[0].keys.include?(:to)
        fail 'Loop must specify :from, :to'
      end
      # assume 1 if :step not provided
      unless args[0].keys.include?(:step)
        args[0][:step] = 1
      end
      # assume 1 if :test_num_inc not provided
      unless args[0].keys.include?(:test_num_inc)
        args[0][:test_num_inc] = 1
      end
      # Add node for set of flag to be used for loop
      unless args[0][:var].nil?
        set(args[0][:var], 0)
      end
      extract_meta!(options) do
        apply_conditions(options) do
          # always pass 5-element array to loop node to simplify downstream parser
          #   element, 'var', will be nil if not specified by loop call
          params = [args[0][:from], args[0][:to], args[0][:step], args[0][:var], args[0][:test_num_inc]]

          node = n(:loop, params)
          node = append_to(node) { block.call }
          node
        end
      end
    end

    RELATIONAL_OPERATORS.each do |method|
      define_method method do |*args, &block|
        options = args.pop if args.last.is_a?(Hash)
        unless args.size == 2
          fail "Format for relational operation must match: ':<operator>(var1, var2)'"
        end
        n2(method.to_sym, args[0], args[1])
      end unless method_defined?(method)
    end

    # Define handlers for all of the flow control block methods, unless a custom one has already
    # been defined above
    CONDITION_KEYS.keys.each do |method|
      define_method method do |*flags, &block|
        if flags.last.is_a?(Hash)
          options = flags.pop
        else
          options = {}
        end
        if flags.include? nil
          Origen.log.error("Found Nil flag passed to the '#{method}' method, ensure the flag is passed as a String or a Symbol!")
          fail
        end
        flags = flags.first if flags.size == 1
        # Legacy option provided by OrigenTesters that permits override of a block enable method by passing
        # an :or option with a true value
        if (CONDITION_KEYS[method] == :if_enabled || CONDITION_KEYS[method] || :unless_enabled) && options[:or]
          block.call
        else
          flow_control_method(CONDITION_KEYS[method], flags, options, &block)
        end
      end unless method_defined?(method)
    end

    def inspect
      "<OrigenTesters::ATP::Flow:#{object_id} #{name}>"
    end

    def ids(options = {})
      OrigenTesters::ATP::AST::Extractor.new.process(raw, [:id]).map { |node| node.to_a[0] }
    end

    private

    def description
      @description.last
    end

    def source_file
      @source_file.last
    end

    def source_line_number
      @source_line_number.last
    end

    def flow_control_method(name, flag, options = {}, &block)
      extract_meta!(options) do
        if flag.is_a?(Array)
          if name == :if_passed
            fail 'if_passed only accepts one ID, use if_any_passed or if_all_passed for multiple IDs'
          end
          if name == :if_failed
            fail 'if_failed only accepts one ID, use if_any_failed or if_all_failed for multiple IDs'
          end
          if name == :if_any_sites_failed || name == :if_all_sites_failed || name == :if_any_sites_passed || name == :if_all_sites_passed
            fail "#{name} currently only accepts one ID, please create a ticket here if you need this functionality: https://github.com/Origen-SDK/origen_testers/issues"
          end
        end
        apply_conditions(options) do
          if block
            node = n1(name, flag)
            open_conditions << [name, flag]
            node = append_to(node) { block.call }
            open_conditions.pop
          else
            unless options[:then] || options[:else]
              fail "You must supply a :then or :else option when calling #{name} like this!"
            end
            node = n1(name, flag)
            if options[:then]
              node = append_to(node) { options[:then].call }
            end
            if options[:else]
              e = n0(:else)
              e = append_to(e) { options[:else].call }
              node = node.updated(nil, node.children + [e])
            end
          end
          node
        end
      end
    end

    def apply_conditions(options, node = nil)
      # Applying the current context, means to append to the same node as the last time, this
      # means that the next node will pick up the exact same condition context as the previous one
      if options[:context] == :current
        node = yield
        found = false
        @pipeline = @pipeline.map do |parent|
          p = Processors::AppendTo.new
          n = p.run(parent, node, @last_append.id)
          found ||= p.succeeded?
          n
        end
        unless found
          fail 'The request to apply the current context has failed, this is likely a bug in OrigenTesters::ATP'
        end
        node
      else
        conditions = extract_conditions(options)
        open_conditions << conditions
        node = yield
        open_conditions.pop

        update_last_append = !condition_node?(node)

        conditions.each do |key, value|
          if key == :group
            node = n2(key, n1(:name, value.to_s), node)
          else
            node = n2(key, value, node)
          end
          if update_last_append
            @last_append = node
            update_last_append = false
          end
        end

        append(node)
        node
      end
    end

    def save_conditions
      @last_conditions = clean_conditions(open_conditions.dup)
    end

    def last_conditions
      @last_conditions || {}
    end

    def open_conditions
      @open_conditions ||= []
    end

    def clean_conditions(conditions)
      result = {}.with_indifferent_access
      conditions.each do |cond|
        if cond.is_a?(Array)
          if cond.size != 2
            fail 'Something has gone wrong in OrigenTesters::ATP!'
          else
            result[cond[0]] = cond[1].to_s if cond[1]
          end
        else
          cond.each { |k, v| result[k] = v.to_s if v }
        end
      end
      result
    end

    def extract_conditions(options)
      conditions = {}
      delete_from_options = !options.delete(:_dont_delete_conditions_)
      options.each do |key, value|
        if CONDITION_KEYS[key]
          options.delete(key) if delete_from_options
          key = CONDITION_KEYS[key]
          if conditions[key] && value
            fail "Multiple values assigned to flow condition #{key}" unless conditions[key] == value
          else
            conditions[key] = value if value
          end
        end
      end
      conditions
    end

    def append(node)
      @last_append = @pipeline.last unless condition_node?(node)
      n = @pipeline.pop
      @pipeline << n.updated(nil, n.children + [node])
      @pipeline.last
    end

    # Append all nodes generated within the given block to the given node
    # instead of the top-level flow node
    def append_to(node)
      @pipeline << node
      yield
      @pipeline.pop
    end

    def condition_node?(node)
      !!CONDITION_KEYS[node.type]
    end

    def extract_meta!(options)
      @source_file << options.delete(:source_file)
      @source_line_number << options.delete(:source_line_number)
      @description << options.delete(:description)
      yield
      @source_file.pop
      @source_line_number.pop
      @description.pop
    end

    def id(name)
      n1(:id, name)
    end

    def priority(name)
      n1(:priority, name)
    end

    def on_fail(options = {})
      if options.is_a?(Proc)
        node = n0(:on_fail)
        append_to(node) { options.call }
      else
        children = []
        if options[:bin] || options[:softbin]
          fail_opts = { bin: options[:bin], softbin: options[:softbin] }
          fail_opts[:bin_description] = options[:bin_description] if options[:bin_description]
          fail_opts[:softbin_description] = options[:softbin_description] if options[:softbin_description]
          fail_opts[:bin_attrs] = options[:bin_attrs] if options[:bin_attrs]
          children << set_result(:fail, fail_opts)
        end
        if options[:set_run_flag] || options[:set_flag]
          children << set_flag_node(options[:set_run_flag] || options[:set_flag])
        end
        children << n0(:continue) if options[:continue]
        children << n1(:delayed, !!options[:delayed]) if options.key?(:delayed)
        children << n1(:render, options[:render]) if options[:render]
        n(:on_fail, children)
      end
    end

    def on_pass(options = {})
      if options.is_a?(Proc)
        node = n0(:on_pass)
        append_to(node) { options.call }
      else
        children = []
        if options[:bin] || options[:softbin]
          pass_opts = { bin: options[:bin], softbin: options[:softbin] }
          pass_opts[:bin_description] = options[:bin_description] if options[:bin_description]
          pass_opts[:softbin_description] = options[:softbin_description] if options[:softbin_description]
          pass_opts[:bin_attrs] = options[:bin_attrs] if options[:bin_attrs]
          children << set_result(:pass, pass_opts)
        end
        if options[:set_run_flag] || options[:set_flag]
          children << set_flag_node(options[:set_run_flag] || options[:set_flag])
        end
        children << n0(:continue) if options[:continue]
        children << n1(:render, options[:render]) if options[:render]
        n(:on_pass, children)
      end
    end

    def pattern(name, path = nil)
      if path
        n2(:pattern, name, path)
      else
        n1(:pattern, name)
      end
    end

    def attribute(name, value)
      n2(:attribute, name, value)
    end

    def level(name, value, units = nil)
      if units
        n(:level, [name, value, units])
      else
        n2(:level, name, value)
      end
    end

    def pin(name)
      n1(:pin, name)
    end

    def set_result(type, options = {})
      children = []
      children << type
      if options[:bin] && options[:bin_description]
        children << n2(:bin, options[:bin], options[:bin_description])
      else
        children << n1(:bin, options[:bin]) if options[:bin]
      end
      if options[:softbin] && options[:softbin_description]
        children << n2(:softbin, options[:softbin], options[:softbin_description])
      else
        children << n1(:softbin, options[:softbin]) if options[:softbin]
      end
      if options[:bin_attrs]
        options[:bin_attrs].each do |key, val|
          children << n1(key, val)
        end
      end
      n(:set_result, children)
    end

    def number(val)
      n1(:number, val.to_i)
    end

    def set_flag_node(flag)
      n1(:set_flag, flag)
    end

    # Ensures the flow ast has a volatile node, then adds the
    # given flags to it
    def add_volatile_flags(node, flags)
      name, *nodes = *node
      if nodes[0] && nodes[0].type == :volatile
        v = nodes.shift
      else
        v = n0(:volatile)
      end
      existing = v.children.map { |f| f.type == :flag ? f.value : nil }.compact
      new = []
      flags.each do |flag|
        new << n1(:flag, flag) unless existing.include?(flag)
      end
      v = v.updated(nil, v.children + new)
      node.updated(nil, [name, v] + nodes)
    end

    # Ensures the flow ast has a global node, then adds the
    # given flags to it
    def add_global_flags(node, flags)
      name, *nodes = *node
      if nodes[0] && nodes[0].type == :global
        v = nodes.shift
      else
        v = n0(:global)
      end
      existing = v.children.map { |f| f.type == :flag ? f.value : nil }.compact
      new = []
      flags.each do |flag|
        new << n1(:flag, flag) unless existing.include?(flag)
      end
      v = v.updated(nil, v.children + new)
      node.updated(nil, [name, v] + nodes)
    end

    # Ensures the flow ast has a bin descriptions node, then adds the
    # given description to it
    def add_bin_description(node, number, description, options)
      @existing_bin_descriptions ||= { soft: {}, hard: {} }
      return node if @existing_bin_descriptions[options[:type]][number]
      @existing_bin_descriptions[options[:type]][number] = true
      name, *nodes = *node
      if nodes[0] && nodes[0].type == :volatile
        v = nodes.shift
      else
        v = nil
      end
      if nodes[0] && nodes[0].type == :bin_descriptions
        d = nodes.shift
      else
        d = n0(:bin_descriptions)
      end
      d = d.updated(nil, d.children + [n2(options[:type], number, description)])
      node.updated(nil, [name, v, d].compact + nodes)
    end

    def n(type, children, options = {})
      options[:file] ||= options.delete(:source_file) || source_file
      options[:line_number] ||= options.delete(:source_line_number) || source_line_number
      options[:description] ||= options.delete(:description) || description
      # Guarantee that each node has a unique meta-ID, in case we need to ever search
      # for it
      options[:id] = OrigenTesters::ATP.next_id
      OrigenTesters::ATP::AST::Node.new(type, children, options)
    end

    def n0(type, options = {})
      n(type, [], options)
    end

    def n1(type, arg, options = {})
      n(type, [arg], options)
    end

    def n2(type, arg1, arg2, options = {})
      n(type, [arg1, arg2], options)
    end
  end
end
