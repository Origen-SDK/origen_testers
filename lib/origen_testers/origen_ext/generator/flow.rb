# This shim is temporary to help NXP transition to Origen from
# our original internal version (RGen)
if defined? RGen::ORIGENTRANSITION
  require 'rgen/generator/flow'
else
  require 'origen/generator/flow'
end
module Origen
  class Generator
    class Flow
      # Create a call stack of flows so that we can work out where the nodes
      # of the ATP AST originated from
      def create(options = {}, &block)
        # Patch for Windows operation since the path can start with something like "C:/"
        if caller[0] =~ /(:(\/|\\))/
          orig_separator = Regexp.last_match(1)
          file, line = *caller[0].sub(/:(\/|\\)/, '_ORIG_SEPARATOR_').split(':')
          file = file.sub('_ORIG_SEPARATOR_', orig_separator)
        else
          file, line = *caller[0].split(':')
        end
        OrigenTesters::Flow.callstack << file
        flow_comments, comments = *_extract_comments(OrigenTesters::Flow.callstack.last, line.to_i)
        OrigenTesters::Flow.comment_stack << comments
        OrigenTesters::Flow.ht_comments = {}
        comments.each do |src_line, com_array|
          flow_src_line = src_line + com_array.size
          OrigenTesters::Flow.ht_comments[flow_src_line] = com_array
        end
        if OrigenTesters::Flow.flow_comments
          top = false
          name = options[:name] || Pathname.new(file).basename('.rb').to_s.sub(/^_/, '')
          # Generate imports as separate sub-flow files on this platform
          if tester.v93k? && tester.smt8?
            # The generate_sub_program method will fork, so this @sub_program will live on in in that thread,
            # where it is used in the _create method to stop the top_level: true option being passed into
            # on_flow_start listeners
            orig_sub_program = @sub_program
            @sub_program = true
            Origen.generator.generate_sub_program(file, options)
            # However, we don't want it to be set for the remainder of the master thread
            @sub_program = orig_sub_program
          else
            Origen.interface.flow.group(name, description: flow_comments) do
              _create(options, &block)
            end
          end
        else
          OrigenTesters::Flow.flow_comments = flow_comments
          if options.key?(:unique_ids)
            OrigenTesters::Flow.unique_ids = options.delete(:unique_ids)
          else
            OrigenTesters::Flow.unique_ids = true
          end
          top = true
          _create(options, &block)
        end
        OrigenTesters::Flow.callstack.pop
        OrigenTesters::Flow.comment_stack.pop
        OrigenTesters::Flow.flow_comments = nil if top
      end

      # @api private
      def _create(options = {}, &block)
        # Refresh the target to start all settings from scratch each time
        # This is an easy way to reset all registered values
        Origen.app.reload_target!
        Origen.tester.generating = :program
        # Make the top level flow globally available, this helps to assign test descriptions
        # to the correct flow whenever tests are instantiated from sub-flows
        if Origen.interface_loaded? && Origen.interface.top_level_flow
          sub_flow = true
          if Origen.tester.doc?
            Origen.interface.flow.start_section
          end
        else
          sub_flow = false
        end
        job.output_file_body = options.delete(:name).to_s if options[:name]
        if sub_flow
          interface = Origen.interface
          opts = Origen.generator.option_pipeline.pop || {}
          Origen.interface.startup(options) if Origen.interface.respond_to?(:startup)
          interface.instance_exec(opts, &block)
          Origen.interface.shutdown(options) if Origen.interface.respond_to?(:shutdown)
          if Origen.tester.doc?
            Origen.interface.flow.stop_section
          end
          interface.close(flow: true, sub_flow: true)
        else
          Origen.log.info "Generating... #{Origen.file_handler.current_file.basename}"
          interface = Origen.reset_interface(options)
          Origen.interface.set_top_level_flow
          Origen.interface.flow_generator.set_flow_description(Origen.interface.consume_comments)
          options[:top_level] = @sub_program ? false : true
          Origen.app.listeners_for(:on_flow_start).each do |listener|
            listener.on_flow_start(options)
          end
          Origen.interface.startup(options) if Origen.interface.respond_to?(:startup)
          if @sub_program
            interface.instance_exec(Origen.generator.option_pipeline.pop || {}, &block)
          else
            interface.instance_eval(&block)
          end
          Origen.interface.shutdown(options) if Origen.interface.respond_to?(:shutdown)
          interface.at_flow_end if interface.respond_to?(:at_flow_end)
          Origen.app.listeners_for(:on_flow_end).each do |listener|
            listener.on_flow_end(options)
          end
          interface.close(flow: true)
        end
      end

      def reset
        Origen.interface.clear_top_level_flow if Origen.interface_loaded?
      end

      def job
        Origen.app.current_job
      end

      def _extract_comments(file, flow_line)
        flow_comments = []
        comments = {}
        comment = nil
        File.readlines(file).each_with_index do |line, i|
          if comment
            if line =~ /^\s*#-(.*)/
              # Nothing, just ignore but keep the comment open
            elsif line =~ /^\s*#(.*)/
              comment << Regexp.last_match(1).strip
            else
              comment = nil
            end
          else
            if line =~ /^\s*#[^-](.*)/
              if i < flow_line
                comment = flow_comments
              else
                comment = []
                comments[i + 1] = comment
              end
              comment << Regexp.last_match(1).strip
            end
          end
        end
        [flow_comments, comments]
      end
    end
  end

  # Provides a hook to enable an internal startup callback to
  class OrigenTestersPersistentFlowCallbackHandler
    include Origen::PersistentCallbacks

    def on_flow_start(options)
      if Origen.interface.respond_to?(:_internal_startup)
        Origen.interface._internal_startup(options)
      end
    end
  end
  # Instantiate an instance of this class immediately when this file is loaded, this object will
  # then listen for the remainder of the Origen thread
  OrigenTestersPersistentFlowCallbackHandler.new
end
