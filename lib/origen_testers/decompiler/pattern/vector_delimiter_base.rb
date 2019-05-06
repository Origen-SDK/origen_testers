module OrigenTesters
  module Decompiler
    class Pattern
      class VectorDelimiterBase
        attr_reader :current_vector
        attr_reader :parent

        def initialize(parent)
          @current_vector = []
          @delimited = false
          @in_comment_block = false

          @parent = parent
        end

        def comment_start
          parent.comment_start
        end

        def in_comment_block?
          @in_comment_block
        end

        def shift(line)
          if @in_comment_block
            if !line.strip.start_with?(comment_start)
              # End of the comment block.
              # Signal that this vector is over, but don't include the
              # newly shifted line.
              @delimited = true
              @include_last_line = false
            else
              @current_vector << line
            end
          else
            if current_vector.empty? && line.strip.start_with?(comment_start)
              # Currently in an empty vector and encountered a comment.
              # Start a new comment block.
              @in_comment_block = true
              @current_vector << line
            elsif !current_vector.empty? && line.strip.start_with?(comment_start)
              # Not in an empty vector, but not in a comment block.
              # Signal the end of this vector and start a new one with
              # this vector.
              @delimited = true
              @include_last_line = false
            else
              # Standard single vector
              @delimited = true
              @include_last_line = true
              @current_vector << line
            end
          end
        end

        def current_vector!
          current_vector.join('')
        end

        def delimited?
          @delimited
        end

        def include_last_line?
          @include_last_line
        end
      end
    end
  end
end
