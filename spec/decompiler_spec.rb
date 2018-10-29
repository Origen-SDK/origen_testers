require 'spec_helper'

RSpec::Matchers.define :match_pins do |expected|
  
  match do |actual|
    expected.each_with_index do |(name, size), i|
      if size > 1
        # Break the pins out into individual pin names
        size.times do |i|
          return false unless actual.key?("#{name}#{i}".to_sym)
        end
      else
        return false unless (actual.key?(name.to_s) || actual.key?(name.upcase.to_s))
      end
    end
    true
  end

  failure_message do |actual|
    "expected pins #{actual.collect { |name, pin| name.to_s + ':' + pin.size.to_s }.join(',') } to match pins #{expected.collect { |name, size| name.to_s + ':' + size.to_s }.join(',') }"
  end
end

RSpec::Matchers.define :match_approved_pattern do |expected|
  match do |actual|
    # Everything is going to be converted to J750, just for simplicity. As the decompiler grows and as new features
    # are added, may need to have per-platform reference patterns.
    return false unless File.exist?(expected)
    return false unless File.exist?(actual)
    
    # check for changes will return true if there's changes, and if there's changes we want to fail the matcher.
    !Origen.generator.check_for_changes(expected, actual)
  end
  
  failure_message do |actual|
    return "Could not find pattern output #{actual}" unless File.exist?(actual)
    return "Could not find pattern reference #{expected}" unless File.exist?(expected)
    
    "Changes occurred when comparing #{expected} to #{actual}"
  end
end

# Each module in testers that supports the decompiler should support the two methods: #add_pins and #execute
RSpec.shared_examples :decompiler_driver do |mod, simple_pattern, complex_pattern, decompiled_pattern_class, env|
  context 'with debug mode' do
    before :context do
      Origen.app.target.temporary = 'empty.rb'
      Origen.app.environment.temporary = env
      Origen.target.load!
      #Origen.load_environment
      
      @simple_pattern = simple_pattern
      @complex_pattern = complex_pattern
      @decompiled_pattern_class = decompiled_pattern_class
      
      ext = simple_pattern.split('.').last
      @pattern_output = "#{Origen.app!.root}/spec/patterns/atp/decompile.#{ext}"
      
      @decmpile_pattern = "#{Origen.app!.root}/pattern/decompile.rb"
      @simple_reference_pattern = "#{Origen.app!.root}/approved/decompiler/simple_decompile.#{ext}"
      @complex_reference_pattern = "#{Origen.app!.root}/approved/decompiler/complex_decompile.#{ext}"
    end
    
    describe "Module spec: #{mod}" do
      it 'responds to #add_pins' do
        expect(mod).to respond_to(:add_pins)
      end
      
      it 'adds the pins to the dut as either pins or pin groups of appropriate size' do
        # instantiate the empty dut and verify it has no pins.
        Origen.target.load!
        expect(Origen.dut.pins).to be_empty
        
        # Attempt to add the pattern's pins
        mod.add_pins(@simple_pattern)
        
        # Verify the DUT has the pins
        expect(dut.pins).to match_pins({tclk: 1, tdi: 1, tdo: 1, tms: 1})
      end

      it 'adds the pins to the dut for a more complex pattern' do
        # instantiate the empty dut and verify it has no pins.
        Origen.target.load!
        expect(Origen.dut.pins).to be_empty

        # Attempt to add the pattern's pins
        mod.add_pins(@complex_pattern)

        # Verify the DUT has the pins
        expect(dut.pins).to match_pins({
          nvm_reset: 1,
          nvm_clk: 1,
          nvm_clk_mux: 1,
          porta: 8,
          portb: 8,
          nvm_invoke: 1,
          nvm_done: 1,
          nvm_fail: 1,
          nvm_alvtst: 1,
          nvm_ahvtst: 1,
          nvm_dtst: 1,
          tclk: 1,
          trst: 1
        })
      end
      
      it 'responds to #execute' do
        expect(mod).to respond_to(:execute)
      end
      
      it 'can execute a pattern' do
        Origen.app.target.temporary = 'dut.rb'
        Origen.target.load!
        
        # Run the pattern generator to get a pattern executed from this pattern
        $DECOMPILE_PATTERN = @simple_pattern
        Origen.app.runner.generate(patterns: [@decmpile_pattern])

        # Invoke Origen's examples handler to compare to the approved
        expect(@pattern_output).to match_approved_pattern(@simple_reference_pattern)
      end
      
      it 'can execute a more complicated pattern' do
        Origen.app.target.temporary = 'legacy.rb'
        Origen.target.load!
        
        # Run the pattern generator to get a pattern executed from this pattern
        $DECOMPILE_PATTERN = @complex_pattern
        Origen.app.runner.generate(patterns: [@decmpile_pattern])
        
        # Invoke Origen's examples handler to compare to the approved
        expect(@pattern_output).to match_approved_pattern(@complex_reference_pattern)
      end
      
      it 'can execute a pattern from a pathname object' do
        Origen.app.target.temporary = 'dut.rb'
        Origen.target.load!
        
        # Run the pattern generator to get a pattern executed from this pattern
        $DECOMPILE_PATTERN = Pathname.new(@simple_pattern)
        Origen.app.runner.generate(patterns: [@decmpile_pattern])
        
        # Invoke Origen's examples handler to compare to the approved
        expect(@pattern_output).to match_approved_pattern(@simple_reference_pattern)
      end
      
      it 'responds to #decompile' do
        expect(mod).to respond_to(:decompile)
      end
      
      it 'can decompile a pattern, yielding an inherited DecompiledPattern' do
        expect(mod.decompile(@simple_pattern)).to be_a(decompiled_pattern_class)
      end
    
      # Test some sample error cases
      
      it 'complains if the file given does not exists' do
        Origen.instance_variable_set(:@debug, true)
        expect {
          mod.execute("unknown_file.atp")
        }.to raise_exception(RuntimeError, /Could not locate pattern source/)
        Origen.instance_variable_set(:@debug, false)
      end
    end

    after :context do
      Origen.app.target.temporary = nil
      Origen.app.environment.temporary = nil
      Origen.target.load!
    end
  end
end

module DecompilerSpec
  describe 'ATP' do
    include_examples(
      :decompiler_driver,
      OrigenTesters::IGXLBasedTester::J750,
      "#{Origen.app!.root}/approved/j750/delay.atp",
      "#{Origen.app!.root}/approved/j750/j750_workout.atp",
      OrigenTesters::IGXLBasedTester::DecompiledPattern,
      "j750.rb",
    )
  end
  
  describe 'AVC' do
    include_examples(
      :decompiler_driver,
      OrigenTesters::SmartestBasedTester::V93K,
      "#{Origen.app!.root}/approved/v93k/delay.avc",
      "#{Origen.app!.root}/approved/v93k/v93k_workout.avc",
      OrigenTesters::SmartestBasedTester::DecompiledPattern,
      "v93k.rb"
    )
  end
end

=begin
# Some basic tests to harden the decompiler API.
module DecompilerSpec
  describe 'Decompiler Spec' do
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
=end
