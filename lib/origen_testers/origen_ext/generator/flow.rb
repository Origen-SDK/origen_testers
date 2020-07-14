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
        options = {
          reload_target: true,
          name:          OrigenTesters::Flow.name_stack.pop
        }.merge(options)
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
            parent, sub_flow = *_sub_flow(name, options, &block)
            path = sub_flow.output_file.relative_path_from(Origen.file_handler.output_directory)
            parent.atp.sub_flow(sub_flow.atp.raw, path: path.to_s)
          else
            Origen.interface.flow.group(name, description: flow_comments) do
              _create(options, &block)
            end
          end
        else
          @top_level_flow = nil
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
      def _sub_flow(name, options, &block)
        @top_level_flow ||= Origen.interface.flow
        parent = Origen.interface.flow
        # If the parent flow already has a child flow of this name then we need to generate a
        # new unique name/id
        # Also generate a new name when the child flow name matches the parent flow name, SMT8.2
        # onwards does not allow this
        if parent.children[name] || parent.name.to_s == name.to_s
          i = 0
          tempname = name
          while parent.children[tempname] || parent.name.to_s == tempname.to_s
            i += 1
            tempname = "#{name}_#{i}"
          end
          name = tempname
        end
        if parent
          id = parent.path + ".#{name}"
        else
          id = name
        end
        sub_flow = Origen.interface.with_flow(id) do
          Origen.interface.flow.instance_variable_set(:@top_level, @top_level_flow)
          Origen.interface.flow.instance_variable_set(:@parent, parent)
          _create(options, &block)
        end
        parent.children[name] = sub_flow
        [parent, sub_flow]
      end

      # @api private
      def _create(options = {}, &block)
        options = {
          reload_target: true
        }.merge(options)
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
          if reload_target?(interface, options)
            Origen.app.reload_target!
            Origen.tester.generating = :program
          end
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
          if reload_target?(interface, options)
            Origen.app.reload_target!
            Origen.tester.generating = :program
          end
          Origen.interface.set_top_level_flow
          Origen.interface.flow_generator.set_flow_description(Origen.interface.consume_comments)
          options[:top_level] = true
          Origen.interface.flow.instance_variable_set('@top_level', Origen.interface.flow)
          Origen.interface.flow.on_top_level_set if Origen.interface.flow.respond_to?(:on_top_level_set)
          Origen.app.listeners_for(:on_flow_start).each do |listener|
            listener.on_flow_start(options)
          end
          Origen.interface.startup(options) if Origen.interface.respond_to?(:startup)
          interface.instance_eval(&block)
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

      def header
        Origen.tester.pre_header if Origen.tester.doc?
        inject_separator
        if $desc
          c2 'DESCRIPTION:'
          $desc.split(/\n/).each { |line| cc line }
          inject_separator
        end
        c2 'GENERATED:'
        c2 "  Time:    #{Origen.launch_time}"
        c2 "  By:      #{Origen.current_user.name}"
        c2 "  Mode:    #{Origen.mode}"
        binding.pry
        l = "  Command: origen p #{job.requested_pattern} -t #{Origen.target.file.basename}"
        if Origen.environment && Origen.environment.file
          l += " -e #{Origen.environment.file.basename}"
        end
        c2(l)
        inject_separator
        c2 'ENVIRONMENT:'
        c2 '  Origen'
        c2 '    Source:    https://github.com/Origen-SDK/origen'
        c2 "    Version:   #{Origen.version}"
        unless Origen.app.plugins.empty?
          c2 '  Plugins'
          Origen.app.plugins.sort_by { |p| p.name.to_s }.each do |plugin|
            c2 "    #{plugin.name}:".ljust(30) + plugin.version
          end
        end
        inject_separator

        unless Origen.app.plugins.empty?
          # Plugins can use config.shared_flow_header to inject plugin-specific comments into the flow header
          header_printed = false
          Origen.app.plugins.sort_by { |p| p.name.to_s }.each do |plugin|
            unless plugin.config.shared_flow_header.nil?
              unless header_printed
                c2 'Header Comments From Shared Plugins:'
                header_printed = true
              end
              inject_flow_header(
                config_loc:      plugin,
                scope:           :shared_flow_header,
                message:         "Header Comments From Shared Plugin: #{plugin.name}:",
                message_spacing: 2,
                line_spacing:    4,
                no_separator:    true
              )
            end
          end
          inject_separator if header_printed
        end

        if Origen.app.plugins.current && !Origen.app.plugins.current.config.send(:current_plugin_flow_header).nil?
          # The top level plugin (if one is set) can further inject plugin-specific comment into the header.
          # These will only appear if the plugin is the top-level plugin though.
          inject_flow_header(
            config_loc: Origen.app.plugins.current,
            scope:      :current_plugin_flow_header,
            message:    "Header Comments From The Current Plugin: #{Origen.app.plugins.current.name}:"
          )
        end

        unless Origen.app.config.send(:application_flow_header).nil?
          inject_flow_header(
            config_loc: Origen.app,
            scope:      :application_flow_header,
            message:    "Header Comments From Application: #{Origen.app.name}:"
          )
        end

        if Origen.config.flow_header
          Origen.log.deprecated 'Origen.config.flow_header is deprecated.'
          Origen.log.deprecated 'Please use config.shared_flow_header, config.application_flow_header, or config.current_plugin_flow_header instead.'
          inject_separator
        end
        Origen.tester.close_text_block if Origen.tester.doc?
      end

      private

      def reload_target?(interface, options)
        if interface.respond_to?(:reload_target)
          # If the test interface cares about reloading the target,
          # it can veto the default behavior of reloading the target
          if interface.reload_target && options[:reload_target]
            true
          else
            false
          end
        elsif options[:reload_target]
          true
        else
          false
        end
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
