module OrigenTesters
  module Decompiler
    class Pattern
      require_relative './base'

      # Represents a single Vector's AST.
      class Vector < Base
        alias_method :parent, :node

        def initialize(parent, options = {})
          super(node: parent, context: parent.context)
        end

        def timeset
          processor.timeset
        end

        def repeat
          processor.repeat
        end

        def pin_states
          processor.pin_states
        end

        def comment
          processor.comment
        end

        def vector_index
          parent.vector_index
        end

        def to_yaml_hash(options = {})
          if parent.type == :vector
            {
              class:          self.class.to_s,
              vector_index:   (parent.respond_to?(:vector_index) ? parent.vector_index : nil),
              type:           parent.type,
              processor:      processor.class.to_s,
              timeset:        timeset,
              repeat:         repeat,
              pin_states:     pin_states,
              comment:        comment,
              platform_nodes: _platform_nodes_
            }
          else
            {
              class:        self.class.to_s,
              vector_index: (parent.respond_to?(:vector_index) ? parent.vector_index : nil),
              type:         parent.type,
              processor:    processor.class.to_s
            }
          end
        end
      end
    end
  end
end
