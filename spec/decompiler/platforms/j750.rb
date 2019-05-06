# Reopen the J750 class and add some spec-centric stuff
require 'origen_testers'

module OrigenTesters
  module Decompiler
    module RSpec
      module J750
        extend Common
        
        @defs = {
          decompiler: OrigenTesters::IGXLBasedTester::Pattern,
          env: 'j750.rb',
          approved_dir: Pathname("#{Origen.app!.root}/approved/j750"),
          patterns: {
            workout: 'j750_workout',
          },
          ext: '.atp',
        }

        def self.handle_platform_specific_vector_body_element(context, vector_type, **test_setup)
          case vector_type
            when :start_label
              context.include_examples(:validate_start_label, test_setup)
            when :global_label
              context.include_examples(:validate_global_label, test_setup)
            when :label
              context.include_examples(:validate_label, test_setup)
          else
            fail "No J750 handler known for vector type :#{vector_type}... cannot continue regression testings."
          end
        end
        
        ::RSpec.shared_examples(:validate_start_label) do |expected:, index:, index_key:, platform:|
          context platform.context_str(platform: 'j750', vector_type: 'start_label', index: index, index_key: index_key) do
            let(:vut) { platform.current.vector_at(index) }
            
            it 'has a processor of type OrigenTesters::IGXLBasedTester::Decompiler::Processor::StartLabel' do
              expect(vut.processor).to be_a(OrigenTesters::IGXLBasedTester::Decompiler::Processors::StartLabel)
            end
                        
            it 'matches an expected start_label, using the :start_label method' do
              expect(vut.processor).to respond_to(:start_label)
              expect(vut.processor.start_label).to eql(expected[:platform_nodes][:start_label])
            end
          end
        end

        ::RSpec.shared_examples(:validate_global_label) do |expected:, index:, index_key:, platform:|
          context platform.context_str(platform: 'j750', vector_type: 'global_label', index: index, index_key: index_key) do
            let(:vut) { platform.current.vector_at(index) }
            
            it 'has a processor of type OrigenTesters::IGXLBasedTester::Decompiler::Processor::GlobalLabel' do
              expect(vut.processor).to be_a(OrigenTesters::IGXLBasedTester::Decompiler::Processors::GlobalLabel)
            end
                        
            it 'matches an expected label name, using the :label_name method' do
              expect(vut.processor).to respond_to(:label_name)
              expect(vut.processor.label_name).to eql(expected[:platform_nodes][:label_name])
            end
          end
        end

        ::RSpec.shared_examples(:validate_label) do |expected:, index:, index_key:, platform:|
          context platform.context_str(platform: 'j750', vector_type: 'label', index: index, index_key: index_key) do
            let(:vut) { platform.current.vector_at(index) }
            
            it 'has a processor of type OrigenTesters::IGXLBasedTester::Decompiler::Processor::Label' do
              expect(vut.processor).to be_a(OrigenTesters::IGXLBasedTester::Decompiler::Processors::Label)
            end
                        
            it 'matches an expected label name, using the :label_name method' do
              expect(vut.processor).to respond_to(:label_name)
              expect(vut.processor.label_name).to eql(expected[:platform_nodes][:label_name])
            end
          end
        end

      end
    end
  end
end

