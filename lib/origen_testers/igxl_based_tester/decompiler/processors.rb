module OrigenTesters
  module IGXLBasedTester
    module Decompiler
      module Processors
        class Frontmatter < OrigenTesters::Decompiler::BaseGrammar::VectorBased::Processors::Frontmatter
          PLATFORM_NODES = [:imports, :variable_assignments]

          def initialize(*args)
            super
            @imports = {}
            @variable_assignments = {}
          end

          # @note Swap the order (as it appears in the source) so we get 'value' => 'type'
          def on_import(node)
            @imports[node.children[1]] = node.children[0]
          end

          def on_variable_assignment(node)
            @variable_assignments[node.children[0]] = node.children[1]
          end
        end

        class Label < Origen::AST::Processor::Base
          PLATFORM_NODES = [:label_name]

          def execute?
            false
          end

          def on_label(node)
            @label_name = node.children.first
          end
        end

        class GlobalLabel < Origen::AST::Processor::Base
          PLATFORM_NODES = [:label_type, :label_name]

          def execute?
            false
          end

          def on_global_label(node)
            @label_type = node.children[0]
            @label_name = node.children[1]
          end
        end

        class StartLabel < Origen::AST::Processor::Base
          PLATFORM_NODES = [:start_label]

          def execute?
            false
          end

          def run(node, options = {})
            process(node)
            self
          end

          def on_start_label(node)
            @start_label = node.children.first
          end
        end

        class Vector < OrigenTesters::Decompiler::BaseGrammar::VectorBased::Processors::Vector
          PLATFORM_NODES = [:opcode, :opcode_arguments]

          def initialize(*args)
            super

            @opcode = nil
            @opcode_arguments = []
          end

          # If the opcode was 'repeat', return the repeat value.
          # Otherwise, return 1.
          def repeat
            opcode == 'repeat' ? opcode_arguments[0].to_i : 1
          end

          def execute?
            true
          end

          def on_opcode(node)
            @opcode = node.children.first
          end

          def on_opcode_arguments(node)
            @opcode_arguments = node.children.map { |n| n.children.first }
          end
        end
      end
    end
  end
end
