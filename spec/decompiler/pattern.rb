RSpec.shared_examples(:decompiled_pattern) do |options|
  describe OrigenTesters::Decompiler::Pattern do
    describe 'class extensions' do
      it 'complains if the parser configuration is missing from the child class' do
        klass = dummy_mods::PatternNoParserConfig
        expect {
          klass.new('', direct_source: true)
        }.to raise_error(
          OrigenTesters::Decompiler::SubclassError,
          /Missing class variable :parser_config/
        )
      end

      it 'complains if the splitter configuration is missing from the child class' do
        klass = dummy_mods::PatternNoSplitterConfig
        expect {
          klass.new('', direct_source: true)
        }.to raise_error(
          OrigenTesters::Decompiler::SubclassError,
          /Missing class variable :splitter_config/
        )
      end
      
      it 'complains if the splitter configuration does not have at least keys :pinlist_start, :vectors_start, and :vectors_end' do
        klass = dummy_mods::PatternIncompleteSplitterConfig
        expect {
          klass.new('', direct_source: true)
        }.to raise_error(
          OrigenTesters::Decompiler::SubclassError,
          /Splitter config is missing required keys: :pinlist_start, :vectors_start/
        )
      end

      it 'does not complain, however, if :no_verify is set during #initialize' do
        klass = dummy_mods::PatternNoParserConfig
        pat = klass.new('', direct_source: true, no_verify: true)
        expect(pat).to be_a(klass)
      end
      
      it 'does not complain, however, if :no_verify is set by the child class' do
        klass = dummy_mods::PatternNoVerify
        pat = klass.new('', direct_source: true)
        expect(pat).to be_a(klass)
      end
      
      context 'with a properly-defined child class' do
        before(:context) do
          @child = OrigenTesters::Decompiler::RSpec.new_dummy_pattern('test', direct_source: true)
        end
        let(:child) { @child }

        it 'retrieves the parser configuration' do
          expect(child.parser_config).to eq({
            platform_grammar_name: 'OrigenTesters::Decompiler::BaseGrammar::VectorBased',
            include_base_tokens_grammar: true,
            include_vector_based_grammar: true,
          })
        end
        
        it 'retrieves the splitter configuration' do
          expect(child.splitter_config).to eql({
            pinlist_start: 0,
            vectors_start: 0,
            vectors_end: -1,
          })
        end
        
        it 'retrieves the platform tokens' do
          expect(child.platform_tokens).to eql({
            comment_start: '#',
            test_token: '!',
          })
        end
        
        it 'can query the comment_start token directly' do
          expect(child.comment_start).to eql('#')
        end
        
        it 'retrieves the platform' do
          expect(child.platform).to eql('dummy')
        end

      end
    end

    # Under the hood, all of the mehods in the API module operate on a 
    # decompiled pattern, which should be inherited from the base OrigenTesters::Decompiler::Pattern.
    # So, for the API itself, we really only need to check that the select_decompiler method can accept the
    # various input types.
    describe 'inputting pattern source' do
      it 'returns a decompiled pattern object from a pattern source (given as a String)' do
        pat = OrigenTesters::Decompiler::RSpec.new_dummy_pattern(rspec.j750.approved_pat(:delay).to_s)
        expect(pat).to be_a(OrigenTesters::Decompiler::Pattern)
        expect(pat.decompiled?).to be(false)
        expect(pat.source).to be_a(Pathname)
        expect(pat.source).to eql(rspec.j750.approved_pat(:delay))
      end
      
      it 'returns a decompiled pattern object from a pattern source (given as a File object)' do
        pat = OrigenTesters::Decompiler::RSpec.new_dummy_pattern(File.new(rspec.j750.approved_pat(:delay).to_s))
        expect(pat).to be_a(OrigenTesters::Decompiler::Pattern)
        expect(pat.decompiled?).to be(false)
        expect(pat.source).to be_a(Pathname)
        expect(pat.source).to eql(rspec.j750.approved_pat(:delay))
      end
      
      it 'returns a decompiled pattern object from a pattern source (given as a Pathname object)' do
        pat = OrigenTesters::Decompiler::RSpec.new_dummy_pattern(Pathname(rspec.j750.approved_pat(:delay)))
        expect(pat).to be_a(OrigenTesters::Decompiler::Pattern)
        expect(pat.decompiled?).to be(false)
        expect(pat.source).to be_a(Pathname)
        expect(pat.source).to eql(rspec.j750.approved_pat(:delay))
      end
      
      it 'complains if the given input source cannot be found' do
        expect {
          pat = OrigenTesters::Decompiler::RSpec.new_dummy_pattern(rspec.missing_atp_src)
        }.to raise_error(
          OrigenTesters::Decompiler::NoSuchSource,
          /Cannot find pattern source '#{rspec.missing_atp_src}'/
        )
      end

      it 'returns a decompiled pattern for the given text input' do
        pat = OrigenTesters::Decompiler::RSpec.new_dummy_pattern(rspec.direct_source, direct_source: true)
        expect(pat).to be_a(OrigenTesters::Decompiler::Pattern)
        expect(pat.decompiled?).to be(false)
        expect(pat.source).to be_a(String)
        expect(pat.source.to_s).to eql(rspec.direct_source)
      end
    end  

    # Note: iterating through vectors gets enough usage in the other tests.
    # Won't test tat explicitly here.
    context "with the J750's delay pattern" do
      before :context do
        #@original_env = Origen.environment.file.basename.to_s
        Origen.environment.temporary = 'j750.rb'
        Origen.load_target('default')

        @pat = OrigenTesters.decompile("#{Origen.app!.root}/approved/j750/delay.atp")

        # The first actual vector element in the delay pattern should be a
        # comment block, followed by the actual first vector.
        @v0 = @pat.vector_at(0)
        @v1 = @pat.vector_at(1)
        @v2 = @pat.vector_at(2)
      end
      
      let(:v0) { @v0 }
      let(:v1) { @v1 }
      let(:v2) { @v2 }
      
      describe 'enumerable extensions' do
        
        describe '#find_all' do
          it 'finds all vector elements for which the given block returns true' do
            vectors = @pat.find_all do |v|
              v.is_a_vector? && v.processor.repeat == 65535
            end
            
            expect(vectors).to be_a(Array)
            expect(vectors.size).to eql(10)
            expect(vectors[0].processor.repeat).to eql(65535)
          end

          it 'returns an empty array if no occurrences are found' do
            vectors = @pat.find_all do |v|
              v.is_a_vector? && v.processor.repeat == 0
            end
            
            expect(vectors).to be_a(Array)
            expect(vectors).to be_empty
          end
        end
      
        describe '#find' do
          it 'finds the first occurrence for which the block returns true' do
            vec = @pat.find do |v|
              v.is_a_vector? && v.processor.repeat == 65535
            end
            
            expect(vec.processor.repeat).to eql(65535)
            expect(vec.vector_index).to eql(2)
          end

          it 'returns nil if no occurrences are found' do
            vectors = @pat.find do |v|
              v.is_a_vector? && v.processor.repeat == 0
            end
            
            expect(vectors).to be_nil
          end
        end
        
        describe '#count' do
          it 'counts the number of vector elements' do
            expect(@pat.count).to eql(14)
          end
          
          it 'counts the number of vector elements for which the given block returns true' do
            cnt = @pat.count do |v|
              v.is_a_vector? && v.processor.repeat == 65535
            end
            
            expect(cnt).to eql(10)
          end
        end

        describe '#reject' do
          it 'finds all vector elements for which the given block returns false' do
            vectors = @pat.reject do |v|
              v.is_a_vector? && v.processor.repeat == 65535
            end

            expect(vectors.size).to be(4)
            expect(vectors[1].is_a_comment?).to be(true)
            expect(vectors[2].processor.repeat).to eql(11316)
            expect(vectors[3].processor.opcode).to eql('end_module')
          end
        end
        
        describe '#find_index' do
          it 'finds the index the first vector for which the block returns true and returns its index' do
            i = @pat.find_index do |v|
              v.is_a_vector? && v.processor.repeat == 65535
            end
            expect(i).to eql(2)
            
            i = @pat.find_index do |v|
              v.is_a_vector? && v.processor.opcode == 'end_module'
            end
            expect(i).to eql(13)
          end
        end
        
        # Note: since the decompiler requires some kind of vector body element (it assumes a parsing error
        # if no vector body elements are found), the cases where the vectors are empty are irrelevant.
        describe '#first' do
          it 'finds the first vector body element' do
            v = @pat.first
            expect(v.processor.start_label).to eql('pattern_st')
          end
          
          it 'finds the first n vector body elements' do
            vectors = @pat.first(3)
            expect(vectors[0].processor.start_label).to eql('pattern_st')
            expect(vectors[1].is_a_comment?).to be(true)
            expect(vectors[2].is_a_vector?).to be(true)
            expect(vectors[2].processor.repeat).to eql(65535)
          end
          
          it 'returns nil if n is zero or negative' do
            v = @pat.first(0)
            expect(v).to be_nil
            
            v = @pat.first(-3)
            expect(v).to be_nil
          end
        end
        
        it 'conforms to common enumerable aliases' do
          expect(@pat.method(:map)).to eql(@pat.method(:collect))

          expect(@pat.method(:filter)).to eql(@pat.method(:find_all))
          expect(@pat.method(:select)).to eql(@pat.method(:find_all))

          expect(@pat.method(:size)).to eql(@pat.method(:count))

          expect(@pat.method(:detect)).to eql(@pat.method(:find))
        end
      end

      describe 'DecompiledVectorBodyElement' do
        it 'knows if it is a vector (#is_a_vector?)' do
          expect(v1.is_a_vector?).to be(false)
          expect(v2.is_a_vector?).to be(true)
        end
        
        it 'knows if it is a comment (#is_a_comment?)' do
          expect(v1.is_a_comment?).to be(true)
          expect(v2.is_a_comment?).to be(false)
        end
        
        it 'knows if it is a tester-specific element (#is_tester_specific?)' do
          expect(v0.is_platform_specific?).to be(true)
          expect(v1.is_platform_specific?).to be(false)
          expect(v2.is_platform_specific?).to be(false)
        end
        
        it 'knows which tester platform it came from (#tester)' do
          expect(v0.tester).to eql('j750')
          expect(v1.tester).to eql('j750')
          expect(v2.tester).to eql('j750')
        end
        
        it 'knows if it was derived from the given tester (#tester?)' do
          expect(v0.tester?('j750')).to be(true)
          expect(v1.tester?('j750')).to be(true)
          expect(v2.tester?('j750')).to be(true)
        end
      end

    end
  end
end
