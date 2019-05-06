module OrigenTesters
  module Decompiler
    class Pattern
      require_relative './base'

      class CommentBlock < Base
        def initialize(parent_or_ast, options = {})
          if parent_or_ast.is_a?(VectorBodyElement)
            @ast = parent_or_ast.ast
            @processor = parent_or_ast.processor
            @parent = parent_or_ast
          end
        end

        def comments
          processor.comments
        end

        def to_yaml_hash(options = {})
          {
            class:          self.class.to_s,
            index:          (@parent.respond_to?(:index) ? @parent.index : nil),
            type:           ast.type,
            processor:      processor.class.to_s,
            comments:       comments,
            platform_nodes: _platform_nodes_
          }
        end
      end
    end
  end
end
