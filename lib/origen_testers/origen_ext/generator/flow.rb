require 'origen/generator/flow'
module Origen
  class Generator
    class Flow
      alias_method :orig_create, :create

      # Create a call stack of flows so that we can work out where the nodes
      # of the ATP AST originated from
      def create(options = {}, &block)
        OrigenTesters::Flow.callstack << caller[0].split(':').first
        OrigenTesters::Flow.comment_stack << _extract_comments(OrigenTesters::Flow.callstack.last)
        orig_create(options, &block)
        OrigenTesters::Flow.callstack.pop
        OrigenTesters::Flow.comment_stack.pop
      end

      def _extract_comments(file)
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
              comment = []
              comment << Regexp.last_match(1).strip
              comments[i] = comment
            end
          end
        end
        comments
      end
    end
  end
end
