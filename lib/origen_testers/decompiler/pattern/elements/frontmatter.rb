module OrigenTesters
  module Decompiler
    class Pattern
      require_relative './base'

      class Frontmatter < Base
        def initialize(node:, context:)
          @source = :frontmatter
          super
        end

        # Returns the topmost comment block.
        # @return [Array] Array representing the topmost common, split by the <code> separator</code>.
        #   If there is no comment header, an empty array is returned.
        def pattern_header
          processor.pattern_header
        end

        # Returns all the comments, in the order they appear.
        # @return [Array] Returns an array of comment blocks, where
        #   a comment block is an array of strings found in that block.
        #   The comment block can be recontructed into raw text by joining the
        #   array with the <code>separator</code>.
        #   If no comments were found, an empty array is returned.
        # @note This will <u>NOT</u> include the <code>comment_header</code>.
        def comments
          processor.comments
        end

        def to_yaml_hash
          {
            class:          self.class.to_s,
            processor:      processor.class.to_s,
            pattern_header: pattern_header,
            comments:       comments,
            platform_nodes: _platform_nodes_
          }
        end
      end
    end
  end
end
