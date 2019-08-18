module OrigenTesters
  module SmartestBasedTester
    module Decompiler
      module Avc
        class SequencerInstruction < OrigenTesters::Decompiler::Nodes::Node
          PLATFORM_NODES = [:instruction, :arguments]

          def initialize(instruction:, arguments: [], context: context)
            @execute = false

            @instruction = instruction
            @arguments = arguments

            super(context: context, type: :sequencer_instruction)
          end
        end

        class Vector < OrigenTesters::Decompiler::Nodes::Vector
        end
      end
    end
  end
end
