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

    # The ATP::FlowAPI provides a render method, but let's grab a handle to the original
    # render method from OrigenTesters, we will use this to extend the ATP render method with
    # the ability to pass in a path to a file containing the content to be rendered into the
    # flow
    alias_method :orig_render, :render

    include ATP::FlowAPI

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

    # Returns true if this is a top-level Origen test program flow
    def top_level?
      top_level == self
    end

    # Returns the flow's parent top-level flow object, or self if this is a top-level flow
    def top_level
      @top_level
    end

    # Returns the flow's immediate parent flow object, or nil if this is a top-level flow
    def parent
      @parent
    end

    # Returns a hash containing all child flows stored by their ID
    def children
      @children ||= {}.with_indifferent_access
    end
    alias_method :sub_flows, :children

    # Returns the flow's ID prefixed with the IDs of its parent flows, joined by '.'
    def path
      @path ||= begin
        ids = []
        p = parent
        while p
          ids.unshift(p.id)
          p = p.parent
        end
        ids << id
        ids.map(&:to_s).join('.')
      end
    end

    def lines
      @lines
    end

    def test(obj, options = {})
      @_last_parameters_ = options.dup # Save for the interface's if_parameter_changed method
      obj.extract_atp_attributes(options) if obj.respond_to?(:extract_atp_attributes)
      super(obj, options)
    end

    # @api private
    def self.ht_comments
      unless @ht_comments.is_a? Hash
        @ht_comments = {}
      end
      @ht_comments
    end

    # @api private
    def self.ht_comments=(val)
      unless @ht_comments.is_a? Hash
        @ht_comments = {}
      end
      @ht_comments = val
    end

    # @api private
    def self.cc_comments
      unless @cc_comments.is_a? Hash
        @cc_comments = {}
      end
      @cc_comments
    end

    # @api private
    def self.cc_comments=(val)
      unless @cc_comments.is_a? Hash
        @cc_comments = {}
      end
      @cc_comments = val
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
          f = program.flow(try(:path) || id, description: OrigenTesters::Flow.flow_comments)
          @sig = flow_sig(try(:path) || id)
          # f.id = @sig if OrigenTesters::Flow.unique_ids
          f
        end
      end
    end
    alias_method :atp, :model

    def render(file, options = {})
      add_meta!(options)
      begin
        text = orig_render(file, options)
      rescue
        text = file
      end
      atp.render(text, options)
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

    # @api private
    def is_the_flow?
      true
    end

    # Returns true if the test context generated from the supplied options + existing condition
    # wrappers is different from that which was applied to the previous test.
    def context_changed?(options)
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

    # This gets called by ATP for all flow generation methods to add the source file information
    # to the generated node
    def add_meta!(options)
      flow_file = OrigenTesters::Flow.callstack.last
      called_from = caller.find { |l| l =~ /^#{flow_file}:.*/ }
      if called_from
        called_from = called_from.split(':')
        options[:source_file] = called_from[0]
        options[:source_line_number] = called_from[1].to_i
      end
    end

    # This gets called by ATP for all flow generation methods to add the description information
    # to the generated node
    def add_description!(options)
      # Can be useful if an app generates additional tests on the fly for a single test in the flow,
      # e.g. a POR, in that case they will not want the description to be attached to the POR, but to
      # the test that follows it
      unless options[:inhibit_description_consumption]
        ht_coms = OrigenTesters::Flow.ht_comments
        cc_coms = OrigenTesters::Flow.cc_comments
        line_no = options[:source_line_number]
        # options[:then] only present on the second iteration of the same test same loop (not sure what this is really)
        # This method is called twice per test method in a loop but the second call should not consume a comment
        if line_no && !options[:then]
          if ht_coms[line_no]
            options[:description] ||= ht_coms[line_no]
          end
          if cc_coms[line_no] && cc_coms[line_no].first
            options[:description] ||= [cc_coms[line_no].shift]
          end
        end
      end
    end
  end
end
