module OrigenTesters
  module IGXLBasedTester
    module Decompiler
      module Processors
        class Label < Origen::AST::Processor::Base
          PLATFORM_NODES = [:label_name]

          def initialize(*args)
            super
          end

          def execute?
            false
          end

          def run(node, options = {})
            process(node)
            self
          end

          def on_label(node)
            @label_name = node.children.first
          end
        end

        class GlobalLabel < Origen::AST::Processor::Base
          PLATFORM_NODES = [:label_type, :label_name]

          def initialize(*args)
            super
          end

          def execute?
            false
          end

          def run(node, options = {})
            process(node)
            self
          end

          def on_global_label(node)
            @label_type = node.children[0]
            @label_name = node.children[1]
          end
        end

        class StartLabel < Origen::AST::Processor::Base
          PLATFORM_NODES = [:start_label]

          def initialize(*args)
            super
          end

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

        class Vector < Origen::AST::Processor::Base
          PLATFORM_NODES = [:opcode, :opcode_arguments]
          # attr_reader :opcode
          # attr_reader :opcode_arguments
          attr_reader :timeset
          attr_reader :pin_states
          attr_reader :comment

          def run(node, options = {})
            @opcode = nil
            @opcode_arguments = []
            @timeset = nil
            @pin_states = []
            @comment = ''
            process(node)
            self
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

          def on_timeset(node)
            @timeset = node.children.first
          end

          def on_pin_state(node)
            @pin_states << node.children.first
          end

          def on_comment(node)
            @comment = node.children.first
          end

          def execute!(context)
            # Apply a timeset switch, if needed.
            unless tester.timeset == timeset
              tester.set_timeset(timeset, 40)
            end

            # Apply the comment
            unless comment.empty?
              cc(comment)
            end

            # Apply the pin states
            context.pinlist.each_with_index do |pin, i|
              dut.pins(pin).vector_formatted_value = pin_states[i]
            end

            # Cycle the tester
            repeat.cycles
          end
        end
      end
    end
  end
end
