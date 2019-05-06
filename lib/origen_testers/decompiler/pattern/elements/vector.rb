module OrigenTesters
  module Decompiler
    class Pattern
      require_relative './base'

      # Represents a single Vector's AST.
      class Vector < Base
        def initialize(parent_or_ast, options = {})
          if parent_or_ast.is_a?(VectorBodyElement)
            @ast = parent_or_ast.ast
            @processor = parent_or_ast.processor
            @parent = parent_or_ast
          else
            @ast = parent_or_ast
            @processor = select_processor.call(node: ast, source: :vector, decompiler: options[:decompiler]).new.run(ast, decompiler: options[:decompiler])
          end
        end

        def timeset
          processor.timeset
        end

        def repeat
          processor.repeat
        end

        def number_of_opcode_arguments
          processor.opcode_arguments.size
        end
        alias_method :number_of_opcode_args, :number_of_opcode_arguments

        def pin_states
          processor.pin_states
        end

        def comment
          processor.comment
        end

        def to_yaml_hash(options = {})
          if @ast.type == :vector
            {
              class:          self.class.to_s,
              vector_index:   (@parent.respond_to?(:vector_index) ? @parent.vector_index : nil),
              type:           @ast.type,
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
              vector_index: (@parent.respond_to?(:vector_index) ? @parent.vector_index : nil),
              type:         @ast.type,
              processor:    processor.class.to_s
            }
          end
        end
      end
    end
  end
end
