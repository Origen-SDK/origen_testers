# This responsibility should be with OrigenTesters, starting to override the methods here
# within OrigenTesters over time and it will be removed from Origen in future once fully
# transferred
require 'origen/generator/pattern'
module Origen
  class Generator
    class Pattern
      # @api private
      def self.convert(file)
        @converting = file
        yield
        @converting = nil
      end

      # @api private
      def self.converting
        @converting
      end

      private

      def converting
        self.class.converting
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
        if converting
          c2 "  Source:  #{converting}"

        else
          l = "  Command: origen g #{job.requested_pattern} -t #{Origen.target.file.basename}"
          if Origen.environment && Origen.environment.file
            l += " -e #{Origen.environment.file.basename}"
          end
          c2(l)
        end
        inject_separator
        c2 'ENVIRONMENT:'
        unless converting
          c2 '  Application'
          if Origen.app.rc
            if Origen.app.rc.git?
              c2 "    Source:    #{Origen.config.rc_url}"
            else
              c2 "    Vault:     #{Origen.config.vault}"
            end
          end
          c2 "    Version:   #{Origen.app.version}"
          unless Origen.app.config.release_externally
            c2 "    Workspace: #{Origen.root}"
          end
          if Origen.app.rc && Origen.app.rc.git?
            begin
              @branch ||= Origen.app.rc.current_branch
              @commit ||= Origen.app.rc.current_commit
              status = "#{@branch}(#{@commit})"
              @pattern_local_mods = !Origen.app.rc.local_modifications.empty? unless @pattern_local_mods_fetched
              @pattern_local_mods_fetched = true
              status += ' (+local edits)' if @pattern_local_mods
              c2 "    Branch:    #{status}"
            rescue
              # No problem, we did our best
            end
          end
        end
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
          # Plugins can use config.shared_pattern_header to inject plugin-specific comments into the patterns header
          header_printed = false
          Origen.app.plugins.sort_by { |p| p.name.to_s }.each do |plugin|
            unless plugin.config.shared_pattern_header.nil?
              unless header_printed
                c2 'Header Comments From Shared Plugins:'
                header_printed = true
              end
              inject_pattern_header(
                config_loc:      plugin,
                scope:           :shared_pattern_header,
                message:         "Header Comments From Shared Plugin: #{plugin.name}:",
                message_spacing: 2,
                line_spacing:    4,
                no_separator:    true
              )
            end
          end
          inject_separator if header_printed
        end

        if Origen.app.plugins.current && !Origen.app.plugins.current.config.send(:current_plugin_pattern_header).nil?
          # The top level plugin (if one is set) can further inject plugin-specific comment into the header.
          # These will only appear if the plugin is the top-level plugin though.
          inject_pattern_header(
            config_loc: Origen.app.plugins.current,
            scope:      :current_plugin_pattern_header,
            message:    "Header Comments From The Current Plugin: #{Origen.app.plugins.current.name}:"
          )
        end

        unless Origen.app.config.send(:application_pattern_header).nil?
          inject_pattern_header(
            config_loc: Origen.app,
            scope:      :application_pattern_header,
            message:    "Header Comments From Application: #{Origen.app.name}:"
          )
        end

        if Origen.config.pattern_header
          Origen.log.deprecated 'Origen.config.pattern_header is deprecated.'
          Origen.log.deprecated 'Please use config.shared_pattern_header, config.application_pattern_header, or config.current_plugin_pattern_header instead.'
          inject_separator
        end
        Origen.tester.close_text_block if Origen.tester.doc?
      end
    end
  end
end
