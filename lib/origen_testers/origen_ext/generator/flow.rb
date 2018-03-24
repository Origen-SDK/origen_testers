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
      alias_method :orig_create, :create

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
          Origen.interface.flow.group(name, description: flow_comments) do
            orig_create(options, &block)
          end
        else
          OrigenTesters::Flow.flow_comments = flow_comments
          if options.key?(:unique_ids)
            OrigenTesters::Flow.unique_ids = options.delete(:unique_ids)
          else
            OrigenTesters::Flow.unique_ids = true
          end
          top = true
          orig_create(options, &block)
        end
        OrigenTesters::Flow.callstack.pop
        OrigenTesters::Flow.comment_stack.pop
        OrigenTesters::Flow.flow_comments = nil if top
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
