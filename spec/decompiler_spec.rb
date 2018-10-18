require 'spec_helper'

# Some basic tests to harden the decompiler API.
module DecompilerSpec
  fdescribe 'Decompiler Spec' do
    context "with debug mode" do
      before :context do
        Origen.instance_variable_set(:@debug, true)
      end
      
      it 'can detect and decomple an ATP' do
        pat = OrigenTesters::Decompiler.decompiler("#{Origen.app!.root}/approved/j750/delay.atp")
        expect(pat).to be_a(OrigenTesters::IGXLBasedTester::DecompiledPattern)
      end
      
      it 'can detect and decompile an AVC' do
        pat = OrigenTesters::Decompiler.decompiler("#{Origen.app!.root}/approved/v93k/delay.avc")
        expect(pat).to be_a(OrigenTesters::SmartestBasedTester::DecompiledPattern)
      end
      
      it 'can also accept either a Pathname or File object' do
        f = "#{Origen.app!.root}/approved/j750/delay.atp"
        
        pat = OrigenTesters::Decompiler.decompiler(File.new(f))
        expect(pat).to be_a(OrigenTesters::IGXLBasedTester::DecompiledPattern)
        
        pat = OrigenTesters::Decompiler.decompiler(Pathname.new(f))
        expect(pat).to be_a(OrigenTesters::IGXLBasedTester::DecompiledPattern)
      end
      
      it 'allows the pattern type to be forced' do
        pat = OrigenTesters::Decompiler.decompiler("#{Origen.app!.root}/approved/j750/delay.atp", decompiler: OrigenTesters::SmartestBasedTester)
        expect(pat).to be_a(OrigenTesters::SmartestBasedTester::DecompiledPattern)
      end
      
      it 'can decompile a string input instead of a file' do
        pat = OrigenTesters::Decompiler.decompiler("#{Origen.app!.root}/approved/j750/delay.atp", decompiler: OrigenTesters::SmartestBasedTester, raw_input: true)
        expect(pat.raw_input?).to be(true)
      end
      
      it 'raises an error if raw input is given but a decompiler is not specified' do
        expect {
          pat = OrigenTesters::Decompiler.decompiler("STRING", raw_input: true)
        }.to raise_error(RuntimeError, "Fail in origen_testers: Decompiler: Option :raw_input requires that the :decompiler option be specified.")
      end
      
      it 'raises an error if the pattern does not exists' do
        expect {
          OrigenTesters::Decompiler.decompile('missing_pattern.atp')
        }.to raise_error(RuntimeError, "Fail in origen_testers: Decompiler: Could not locate pattern source at missing_pattern.atp")
      end
      
      context 'with decompiled ATP' do
        before :context do
          @pat = OrigenTesters::Decompiler.decompiler("#{Origen.app!.root}/approved/j750/delay.atp")
        end
        
        it 'is initialized without decompiling' do
          expect(@pat).to be_a(OrigenTesters::IGXLBasedTester::DecompiledPattern)
          expect(@pat.decompiled?).to be(false)
        end
        
        it 'decompiles the pattern' do
          @pat.decompile
          expect(@pat.decompiled?).to be(true)
          expect(@pat.pattern_model).to be_a(OrigenTesters::IGXLBasedTester::Decompiler::Atp::Atp)
        end

        it 'retains the compiled pattern name' do
          expect(@pat.input).to eql("#{Origen.app!.root}/approved/j750/delay.atp")
        end
        
        it 'retains whether the input was a string' do
          expect(@pat.raw_input?).to be(false)
        end
        
        # The test below are gross tests to make sure the API is stable. The actual values should be checked during
        # examples. These will still fail if the decompiler is broken, but this won't give very helpful feedback.
        
        it 'can retrieve the decompiled vectors' do
          expect(@pat.vectors).to be_a(Array)
          expect(@pat.vectors.size).to be(13)
          expect(@pat.vectors[0]).to be_a(OrigenTesters::Decompiler::BaseGrammar::CommentBlock)
          expect(@pat.vectors[-1]).to be_a(OrigenTesters::IGXLBasedTester::Decompiler::Atp::Vector)
        end
        
        it 'can retrieve the decompiled pinlist' do
          expect(@pat.pinlist).to eql([
            'tclk', 'tdi', 'tdo', 'tms'
          ])
        end
      end
      
      after :context do
        Origen.instance_variable_set(:@debug, false)
      end
    end
  end
end
