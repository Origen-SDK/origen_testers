module OrigenTesters
  module IGXLBasedTester
    module Decompiler
      module Atp
        class Vector < OrigenTesters::Decompiler::Nodes::Vector
          def initialize(**options)
            @opcode = options[:opcode]
            @opcode_arguments = options[:opcode_arguments] || []
            super(repeat: false, **options)
          end

          def repeat
            opcode == 'repeat' ? opcode_arguments.first.to_i : 1
          end

          def opcode
            @opcode
          end

          def opcode_arguments
            @opcode_arguments
          end
        end

        class StartLabel < OrigenTesters::Decompiler::Nodes::Node
          PLATFORM_NODES = [:start_label]

          def initialize(start_label:, context:)
            @execute = false
            @start_label = start_label

            super(context: context, type: :start_label)
          end
        end

        class Frontmatter < OrigenTesters::Decompiler::Nodes::Frontmatter
          PLATFORM_NODES = [:variable_assignments, :imports]

          def initialize(pattern_header:, comments:, variable_assignments:, imports:, context: context)
            @variable_assignments = variable_assignments
            @imports = imports

            super(pattern_header: pattern_header, comments: comments, context: context)
          end
        end

        class CommentBlock < OrigenTesters::Decompiler::Nodes::CommentBlock
        end

        class Label < OrigenTesters::Decompiler::Nodes::Node
          PLATFORM_NODES = [:label_name]

          def initialize(label_name:, context:)
            @execute = false
            @label_name = label_name

            super(context: context, type: :label)
          end
        end

        class GlobalLabel < OrigenTesters::Decompiler::Nodes::Node
          PLATFORM_NODES = [:label_type, :label_name]

          def initialize(label_type:, label_name:, context:)
            @execute = false
            @label_type = label_type
            @label_name = label_name

            super(context: context, type: :global_label)
          end
        end
      end
    end
  end
end
