require 'digest/md5'
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

    def self.flow_comments
      @flow_comments
    end

    def self.flow_comments=(val)
      @flow_comments = val
    end

    def self.unique_ids
      @unique_ids
    end

    def self.unique_ids=(val)
      @unique_ids = val
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
        @model ||= begin
          f = program.flow(id, description: OrigenTesters::Flow.flow_comments)
          @sig = flow_sig(id)
          f.id = @sig if OrigenTesters::Flow.unique_ids
          f
        end
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
      options[:bin_description] ||= options.delete(:description)
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
    # This fires between target loads (unless overridden by the ATE specific flow class)
    def at_run_start
      @@program = nil
    end

    # @api private
    # This fires between flows (unless overridden by the ATE specific flow class)
    def at_flow_start
      @labels = {}
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

    def if_flag(flag, options = {})
      options = { if_flag: flag }
      add_meta!(options)
      model.with_conditions(options) do
        yield
      end
    end

    def unless_flag(flag, options = {})
      options = { unless_flag: flag }
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

    def generate_unique_label(name = nil)
      name = 'label' if !name || name == ''
      name.gsub!(' ', '_')
      name.upcase!
      @labels ||= {}
      @labels[name] ||= 0
      @labels[name] += 1
      "#{name}_#{@labels[name]}_#{sig}"
    end

    # Returns a unique signature that has been generated for the current flow, this can be appended
    # to named references to avoid naming collisions with any other flow
    def sig
      @sig
    end
    alias_method :signature, :sig

    private

    # Make a unique signature for the flow based on the flow name and the name of
    # the plugin/app that owns it
    def flow_sig(id)
      s = Digest::MD5.new
      # These guarantee uniqueness within a plugin/app
      s << id.to_s
      s << filename
      # This will add the required plugin uniqueness in the case of a top-level app
      # that has multiple plugins that can generate test program snippets
      if file = OrigenTesters::Flow.callstack.first
        s << get_app(file).name.to_s
      end
      s.to_s[0..6].upcase
    end

    def get_app(file)
      path = Pathname.new(file).dirname
      until File.exist?(File.join(path, 'config/application.rb')) || path.root?
        path = path.parent
      end
      if path.root?
        fail 'Something went wrong resoving the app root in OrigenTesters'
      end
      Origen.find_app_by_root(path)
    end

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
      # Can be useful if an app generates additional tests on the fly for a single test in the flow,
      # e.g. a POR, in that case they will not want the description to be attached to the POR, but to
      # the test that follows it
      unless options[:inhibit_description_consumption]
        comments = OrigenTesters::Flow.comment_stack.last
        if options[:source_line_number]
          while comments.first && comments.first.first < options[:source_line_number]
            options[:description] ||= []
            c = comments.shift
            if c[0] + c[1].size == options[:source_line_number]
              options[:description] += c[1]
            end
          end
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
