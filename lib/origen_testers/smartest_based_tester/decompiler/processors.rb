module OrigenTesters
  module SmartestBasedTester
    module Decompiler
      module Processors
        class SequencerInstruction < Origen::AST::Processor::Base
          PLATFORM_NODES = [:instruction, :arguments]

          def on_sequencer_instruction(node)
            @instruction = node.children[0]
            @arguments = node.children[1..-1]
          end
        end

        class Vector < OrigenTesters::Decompiler::BaseGrammar::VectorBased::Processors::Vector
          def run(node, options = {})
            # Need to query the pinlist size from earlier in the pattern.
            # The pin_states and comment fields are combined where any word-tokens
            # less than/equal to the pinlist size is a pin state, but anything
            # more is a comment.
            @pinlist_size = options[:decompiled_pattern].pinlist_size
            super
          end

          def on_pin_state(node)
            if @pin_states.size < @pinlist_size
              @pin_states << node.children.first
            elsif @comment.empty?
              @comment += node.children.first
            else
              @comment += " #{node.children.first}"
            end
          end
        end
      end
    end
  end
end
