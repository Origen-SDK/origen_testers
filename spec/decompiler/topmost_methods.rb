# The main methods present on the Decompiler class.
# Unlike the tests ./decompiler_api.rb, these are actually running going for
# validation/correctness, not merely making sure they're there.

# These are the most advertised, key, methods of the decompiler. That is, if
# nothing else, make sure these methods work as expected.

RSpec.shared_examples(:decompiler_top_methods) do |options|
  describe 'Decompiler top-most methods' do

    describe '#add_pins' do
      context 'with an DUT containing no pins' do
        before :context do
          Origen.app.target.temporary = 'empty.rb'
          Origen.app.environment.temporary = 'j750.rb'
        end
        
        before :each do
          Origen.target.load!
        end
        
        it 'adds the pins from the the delay pattern to the DUT (simple case)' do
          # Make sure we've got expected pins
          expect(dut.pins).to be_empty

          pat = OrigenTesters.decompile(rspec.j750.approved_pat(:delay))
          added_pins = pat.add_pins

          # Check the return value of #add_pins
          expect(added_pins).to eql(rspec.delay_pattern_pins.keys)
          
          # Check the pins were added to the DUT
          expect(dut.pins).to match_pins(rspec.delay_pattern_pins)
        end
        
        it 'adds the pins from the workout pattern to the DUT, with appropriate sizes (complex case)' do
          # Make sure we've got expected pins
          expect(dut.pins).to be_empty


          pat = OrigenTesters.decompile(rspec.j750.approved_pat(:workout))
          added_pins = pat.add_pins

          # Check the return value of #add_pins
          expect(added_pins).to eql(rspec.workout_pattern_pins.keys)
          
          # Check the pins were added to the DUT
          expect(dut.pins).to match_pins(rspec.workout_pattern_pins)
        end

        after :context do
          Origen.app.target.temporary = nil
          Origen.app.environment.temporary = nil
          Origen.target.load!
        end
      end
      
      context 'with a DUT containing some of or all of the pattern\'s pins' do
        before :context do
          Origen.app.target.temporary = 'dut.rb'
          Origen.app.environment.temporary = 'j750.rb'
        end

        before :each do
          Origen.target.load!
        end

        it 'only adds the pins which are not currently present on the DUT' do
          # Make sure we've got expected pins
          expect(dut.pins).to match_pins(rspec.dut_pins)

          pat = OrigenTesters.decompile(rspec.j750.approved_pat(:workout))
          added_pins = pat.add_pins

          # Check the return value of #add_pins
          # (All pins except :tclk should have been added)
          expect(added_pins).to eql([:nvm_reset, :nvm_clk, :nvm_clk_mux, :porta, :portb, :nvm_invoke, :nvm_done, :nvm_fail, :nvm_alvtst, :nvm_ahvtst, :nvm_dtst, :trst])
          
          # Check the pins were added to the DUT
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
            tdi: 1,
            tdo: 1,
            tms: 1,
            trst: 1
          })
        end
        
        it 'adds no pins if the DUT already contains all of the pins in the pattern' do
          # Make sure we've got expected pins
          expect(dut.pins).to match_pins(rspec.dut_pins)

          pat = OrigenTesters.decompile(rspec.j750.approved_pat(:delay))
          added_pins = pat.add_pins

          # Check the return value of #add_pins
          expect(added_pins).to be_empty
          
          # Check the pins were added to the DUT
          expect(dut.pins).to match_pins(rspec.dut_pins)
        end

        after :context do
          Origen.app.target.temporary = nil
          Origen.app.environment.temporary = nil
          Origen.target.load!
        end
      end
      
      context 'with no first vector required (v93k)' do
        before :context do
          Origen.app.target.temporary = 'empty.rb'
          Origen.app.environment.temporary = 'j750.rb'
          Origen.target.load!
        end

        it 'raises an error if no first vector is available in the pattern' do
          pat = OrigenTesters.decompile(rspec.v93k.approved_pat(:simple))
          expect {
            pat.add_pins
          }.to raise_error(OrigenTesters::Decompiler::NoFirstVectorAvailable, /Cannot add pins to the DUT 'OrigenTesters::Test::EmptyDUT'/)
        end
        
        after :context do
          Origen.app.target.temporary = nil
          Origen.app.environment.temporary = nil
          Origen.target.load!
        end
      end
    end
    
    describe '#execute' do
      context 'with the J750 as the target output' do
        before :context do
          Origen.app.environment.temporary = 'j750.rb'
          @plat = OrigenTesters::Decompiler::RSpec.j750
        end
        
        it 'can execute the delay pattern' do
          Origen.app.target.temporary = 'dut.rb'
          Origen.target.load!
          
          # Run the pattern generator to get a pattern executed from this pattern
          puts @plat.approved_pat(:delay)
          r = @plat.generate_execution_result(@plat.approved_pat(:delay))

          # Invoke Origen's examples handler to compare to the approved
          expect(r).to match_approved_pattern(@plat.execution_result('delay'))
        end
        
        it 'can execute the workout pattern' do
          Origen.app.target.temporary = 'legacy.rb'
          Origen.target.load!
          
          # Add the timesets here to not conflict elsewhere.
          # These will be reset after this test ends
          dut.add_timeset('nvmbist')
          dut.add_timeset('nvm_slow')
          dut.timeset('nvm_slow') do |t|
            t.period_in_ns = 200
          end
          
          # Run the pattern generator to get a pattern executed from this pattern
          r = @plat.generate_execution_result(:workout)
          
          # Invoke Origen's examples handler to compare to the approved
          expect(r).to match_approved_pattern(@plat.execution_result(:workout))
        end

        after :context do
          Origen.app.target.temporary = nil
          Origen.app.environment.temporary = nil
          Origen.target.load!
        end
      end
    end

  end
end

