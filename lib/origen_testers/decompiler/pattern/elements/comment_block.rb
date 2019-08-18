module OrigenTesters
  module Decompiler
    class Pattern
      require_relative './base'

      class CommentBlock < Base
        def initialize(parent)
          super(node: parent, context: parent.context)
        end

        def comments
          processor.comments
        end

        def to_yaml_hash(options = {})
          {
            class:          self.class.to_s,
            index:          (node.respond_to?(:index) ? node.index : nil),
            type:           node.type,
            processor:      node.class.to_s,
            comments:       comments,
            platform_nodes: _platform_nodes_
          }
        end
      end
    end
  end
end
