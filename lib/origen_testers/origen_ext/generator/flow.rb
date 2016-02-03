require 'origen/generator/flow'
module Origen
  class Generator
    class Flow
      alias_method :orig_create, :create

      # Create a call stack of flows so that we can work out where the nodes
      # of the ATP AST originated from
      def create(options = {}, &block)
        file, line = *caller[0].split(':')
        OrigenTesters::Flow.callstack << file
        # The flow comments are just being discarded for now, but should be attached to a
        # flow/group wrapper node in future
        flow_comments, comments = *_extract_comments(OrigenTesters::Flow.callstack.last, line.to_i)
        OrigenTesters::Flow.comment_stack << comments
        orig_create(options, &block)
        OrigenTesters::Flow.callstack.pop
        OrigenTesters::Flow.comment_stack.pop
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
end
