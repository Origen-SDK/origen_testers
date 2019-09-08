RSpec.shared_examples(:decompiler_api) do |options|
  describe 'DecompilerAPI' do

    # This is the generalized 'find a decompiler and decompile' interface.
    # Provided as a module so anything can include this without having to worry
    # about handling all cases.
    context 'without a #suitable_decompiler_for method' do
      before(:context) do
        Origen.app.target.temporary = 'default.rb'
        Origen.app.environment.temporary = 'j750.rb'
        Origen.target.load!
      end
      
      describe '#decompile' do
        it 'decompiles a pattern from the given pattern source' do
          pat = dummy_mod.decompile(rspec.j750.approved_pat(:delay))
          expect(pat).to be_a(OrigenTesters::IGXLBasedTester::Pattern)
          expect(pat.decompiled?).to be(true)
        end

        it 'will use the provided decompiler' do
          expect {
            dummy_mod.decompile(rspec.j750.approved_pat(:delay), decompiler: OrigenTesters::SmartestBasedTester::Pattern)
          }.to raise_error(OrigenTesters::Decompiler::ParseError)
        end
      end
      
      describe '#decompiled_pattern' do
        it 'returns a decompiled pattern object from a pattern source (given as a String)' do
          pat = dummy_mod.decompiled_pattern(rspec.j750.approved_pat(:delay))
          expect(pat).to be_a(OrigenTesters::IGXLBasedTester::Pattern)
          expect(pat.decompiled?).to be(false)
        end

        it 'will use the provided decompiler' do
          pat = dummy_mod.decompiled_pattern(rspec.j750.approved_pat(:delay), decompiler: OrigenTesters::SmartestBasedTester::Pattern)
          expect(pat).to be_a(OrigenTesters::SmartestBasedTester::Pattern)
          expect(pat.decompiled?).to be(false)
        end
      end
      
      describe '#decompile_text' do
        it 'returns a decompiled pattern for the given text input, using the provided decompiler' do
          # Since we're using a J750 source on a v93k decompiler, we'd expect a parsing error
          expect {
            pat = dummy_mod.decompile_text(rspec.direct_source, decompiler: OrigenTesters::SmartestBasedTester::Pattern)
          }.to raise_error(OrigenTesters::Decompiler::ParseError)
        end

        it 'returns a decompiled pattern for the given text input, using the current environment as the decompiler module' do
          pat = dummy_mod.decompile_text(rspec.direct_source)
          expect(pat).to be_a(OrigenTesters::IGXLBasedTester::Pattern)
          expect(pat.decompiled?).to be(true)

          expect(pat.first_vector).to_not be(nil)
          expect(pat.first_vector.repeat).to be(rspec.direct_source_first_vector_repeat_count)
        end
      end

      describe '#select_decompiler' do
        it 'selects the given decompiler suitable to parse the pattern source (given as a String)' do
          expect(dummy_mod.decompiler(rspec.j750.approved_pat(:delay))).to eql(OrigenTesters::IGXLBasedTester::Pattern)
        end

        it 'selects the given decompiler suitable to parse the pattern source (given as a File object)' do
          expect(dummy_mod.decompiler(File.new(rspec.j750.approved_pat(:delay)))).to eql(OrigenTesters::IGXLBasedTester::Pattern)
        end

        it 'selects the given decompiler suitable to parse the pattern source (given as a Pathname)' do
          expect(dummy_mod.decompiler(Pathname.new(rspec.j750.approved_pat(:delay)))).to eql(OrigenTesters::IGXLBasedTester::Pattern)
        end

        it 'returns nil if no suitable decompiler can be found' do
          expect(dummy_mod.select_decompiler(rspec.unknown_src)).to be_nil
        end
       
        it 'DOES NOT complain if the given input source cannot be found' do
          expect(dummy_mod.decompiler(rspec.missing_atp_src)).to eql(OrigenTesters::IGXLBasedTester::Pattern)
        end

        it 'selects the decompiler for the current environment if no input source is given' do
          expect(dummy_mod.decompiler).to eql(OrigenTesters::IGXLBasedTester::Pattern)
        end
        
        it 'complains if the current environment does not support decompilation' do
          env = Origen.environment.file.basename.to_s
          Origen.environment.temporary = 'dummy.rb'
          Origen.load_target('default')
          expect(dummy_mod.select_decompiler).to be_nil

          Origen.environment.temporary = env
          Origen.load_target('default')
        end
        
        it 'complains if the current environment does not instantiate a tester for decompilation (e.g., tester #=> nil)' do
          env = Origen.environment.file.basename.to_s
          Origen.environment.temporary = 'unsupported_decompiler.rb'
          Origen.load_target('default')
          expect(dummy_mod.select_decompiler).to be_nil

          Origen.environment.temporary = env
          Origen.load_target('default')
        end
      end

      describe '#select_decompiler!' do
        it 'complains if no suitable decompiler can be found' do
          expect {
            dummy_mod.select_decompiler!(rspec.unknown_src)
          }.to raise_error(
            OrigenTesters::Decompiler::NoSuitableDecompiler,
            /Cannot find a suitable decompiler for pattern source '#{rspec.unknown_src}' \('.unknown'\)/
          )
        end

        it 'complains if the current environment does not support decompilation' do
          #Origen.environment.temporary = 'no_decompiler.rb'
          env = Origen.environment.file.basename.to_s
          Origen.environment.temporary = 'unsupported_decompiler.rb'
          Origen.load_target('default')
          expect {
            dummy_mod.select_decompiler!
          }.to raise_error(
            OrigenTesters::Decompiler::NoSuitableDecompiler,
            /Current environment 'unsupported_decompiler.rb' does not contain a suitable decompiler! Cannot select this as the decompiler./
          )          

          Origen.environment.temporary = env
          Origen.load_target('default')
        end
      end
      
      # Methods #execute, #add_pins, and #convert will have other tests upstream
      # Just want to make sure here that we correctly provide an interface/shortcut
      # into the decompiled pattern object.
      # We'll check that we get some output, but the output won't be verified here.
      describe '#execute' do
        it 'responds to #execute' do
          expect(dummy_mod).to respond_to(:execute)
        end
        
        it 'can execute from a given source pattern' do
          expect(dummy_mod.execute(rspec.j750.approved_pat(:delay))).to be_a(OrigenTesters::IGXLBasedTester::Pattern)
        end

        it 'will use the provided decompiler' do
          expect {
            dummy_mod.execute(rspec.j750.approved_pat(:delay), decompiler: OrigenTesters::SmartestBasedTester::Pattern)
          }.to raise_error(OrigenTesters::Decompiler::ParseError)
        end
      end
      
      describe '#add_pins' do
        it 'responds to #add_pins' do
          expect(dummy_mod).to respond_to(:add_pins)
        end

        it 'can add pins from a given source pattern' do
          expect(dummy_mod.add_pins(rspec.j750.approved_pat(:delay))).to be_empty
        end

        it 'will use the provided decompiler' do
          expect {
            dummy_mod.add_pins(rspec.j750.approved_pat(:delay), decompiler: OrigenTesters::SmartestBasedTester::Pattern)
          }.to raise_error(OrigenTesters::Decompiler::ParseError)
        end
      end
      
      describe '#registered_decompilers' do
        it 'can return the current registered decompilers' do
          expect(dummy_mod.registered_decompilers).to include(OrigenTesters::IGXLBasedTester, OrigenTesters::SmartestBasedTester)
        end
      end
      
      describe '#register_decompiler' do
        it 'can register a new decompiler, returning true if the decompiler was not previously added, or false if it was' do
          expect(dummy_mod.registered_decompilers).to_not include(rspec.dummy_mod_with_decompiler)

          expect(dummy_mod.register_decompiler(rspec.dummy_mod_with_decompiler)).to be(true)
          expect(dummy_mod.registered_decompilers).to include(rspec.dummy_mod_with_decompiler)

          expect(dummy_mod.register_decompiler(rspec.dummy_mod_with_decompiler)).to be(false)
          expect(dummy_mod.registered_decompilers).to include(rspec.dummy_mod_with_decompiler)
        end
        
        it 'complains if the newly registered decompiler does not provide a #suitable_decompiler_for method' do
          # Check that the decompiler provides a #suitable_decompiler_for method
          expect {
            expect(dummy_mod.register_decompiler(rspec.dummy_mod_incomplete_decompiler))
          }.to raise_error(
            OrigenTesters::Decompiler::NoMethodError,
            /No method #suitable_decompiler_for found on #{rspec.dummy_mod_incomplete_decompiler}. Cannot register as a decompiler/
          )
        end
      end
      
      describe 'decompiler_for?' do
        it 'returns true if a suitable decompiler can be found for the given pattern source' do
          expect(dummy_mod.decompiler_for?(rspec.j750.approved_pat(:delay))).to be(true)
        end
        
        it 'returns false if a suitable decompiler cannot be found for the given pattern source' do
          expect(dummy_mod.decompiler_for?(rspec.unknown_src)).to be(false)
        end
      end
    end

    context 'with the decompiler providing a #suitable_decompiler_for method' do
      # This is a module which contains the decompiler. The calls are very
      # similar to the non-decompiler-module case, except searching for a
      # suitable decompiler is limited to this module.
      
      it 'always selects the module' do
        expect(OrigenTesters::IGXLBasedTester.decompiler(rspec.j750.approved_pat(:delay))).to eql(OrigenTesters::IGXLBasedTester::Pattern)
        expect(OrigenTesters::IGXLBasedTester.decompiler(rspec.v93k.approved_pat(:delay))).to be_nil
        expect(OrigenTesters::IGXLBasedTester.decompiler(rspec.unknown_src)).to be_nil
      end
    end

    after :context do
      # Reset the tester and target
      Origen.environment.temporary = nil
      Origen.load_target('default')
    end
  end
end
