# Reopen the V93K class and add some spec-centric stuff
require 'origen_testers'

module OrigenTesters
  module Decompiler
    module RSpec
      module V93K
        extend Common

        @defs = {
          decompiler: OrigenTesters::SmartestBasedTester::Pattern,
          env: 'v93k.rb',
          approved_dir: Pathname("#{Origen.app!.root}/approved/v93k"),
          patterns: {
            workout: 'v93k_workout',
          },
          ext: '.avc',
        }

        def self.handle_platform_specific_vector_body_element(context, vector_type, **test_setup)
          case vector_type
            when :sequencer_instruction
              context.include_examples(:sequencer_instruction, test_setup)
            else
              fail "No J750 handler known for vector type :#{vector_type}... cannot continue regression testings."
          end
        end

        ::RSpec.shared_examples(:sequencer_instruction) do |expected:, index:, index_key:, platform:|
          context platform.context_str(platform: 'v93k', vector_type: 'sequencer_instruction', index: index, index_key: index_key) do
            let(:vut) { platform.current.vector_at(index) }
            
            it 'has a processor of type OrigenTesters::SmartestBasedTester::Decompiler::Processors::SequencerInstruction' do
              expect(vut.processor).to be_a(OrigenTesters::SmartestBasedTester::Decompiler::Processors::SequencerInstruction)
            end
                        
            it 'matches an expected instruction, using the :instruction method' do
              expect(vut.processor).to respond_to(:instruction)
              expect(vut.processor.instruction).to eql(expected[:platform_nodes][:instruction])
            end

            it 'matches an expected arguments, using the :arguments method' do
              expect(vut.processor).to respond_to(:arguments)
              expect(vut.processor.arguments).to eql(expected[:platform_nodes][:arguments])
            end
          end
        end
        
      end
    end
  end
end

