require 'spec_helper'

# Given an array containing the timeset name and the expected period in ns, 
# checks that the current timeset matches the same name and period
RSpec::Matchers.define :describe_current_timeset do
  match do |parameters|
    @failures = []
    if tester.timeset.name.to_sym != parameters[0].to_sym
      @failures << "Expected current timeset to have name #{parameters[0]} - Received #{tester.timeset.name}"
    end
    
    if dut.timeset.name.to_sym != parameters[0].to_sym
      @failures << "Expected the DUT's current timeset to have name #{parameters[0]} - Received #{dut.timeset.name}"
    end
    
    if tester.timeset.period_in_ns != parameters[1]
      @failures << "Expected current timeset to have period_in_ns #{parameters[1]} - Received #{tester.timeset.period_in_ns}"
    end
    
    if dut.current_timeset_period != parameters[1]
      @failures << "Expected the DUT's current period in ns to be #{parameters[1]} - Received #{dut.current_timeset_period}"
    end
    
    if dut.timesets[parameters[0]]
      if dut.timesets[parameters[0]].period_in_ns != parameters[1]
        @failures << "Expected DUT timeset #{parameters[0]} to have period_in_ns #{parameters[1]} - Received #{dut.timesets[parameters[0]].period_in_ns}"
      end
    end
    
    @failures.empty?
  end
  
  failure_message do |actual|
    message = ["Current timeset does not match expected description:"]
    message += @failures.collect { |f| " #{f}" }
    message.join("\n")
  end
end

describe "Timing APIs" do
  let(:default_period) { 1 }
  let(:updated_period) { 2 }

  describe 'Simple Timesets' do
    before(:all) do
      # Save the current target
      @old_target = "#{Origen.target.name}.rb"
    end
    
    before(:each) do
      Origen.environment.temporary = "j750.rb"
      Origen.load_target("dut.rb")
      expect(dut.current_timeset_period).to be(nil)
      tester.set_timeset("func", default_period)
    end
    
    it "Setting the tester timeset also updates the DUT" do
      expect(dut.current_timeset_period).to eql(default_period)
    end
    
    it 'raises an error if the period_in_ns changes during the course of the pattern' do
      tester.cycle
      expect {
        tester.set_timeset("func", updated_period)
      }.to raise_error(OrigenTesters::Timing::InvalidModification, /Timeset :func's period_in_ns cannot be changed after a cycle has occurred using this timeset!/) 
      expect([:func, default_period]).to describe_current_timeset
    end

    it 'can set the period_in_ns of a new timeset when it is first used during the course of a pattern, but then cannot be changed' do
      tester.cycle
      tester.set_timeset("func2", updated_period)
      tester.cycle
      expect {
        tester.set_timeset("func2", default_period)
      }.to raise_error(OrigenTesters::Timing::InvalidModification, /Timeset :func2's period_in_ns cannot be changed after a cycle has occurred using this timeset!/) 
      expect([:func2, updated_period]).to describe_current_timeset
    end

    it 'can switch to an existing timeset, provided the period_in_ns does not change' do
      tester.cycle

      tester.set_timeset("func2", updated_period)
      expect([:func2, updated_period]).to describe_current_timeset
      tester.cycle

      tester.set_timeset("func", default_period)
      expect([:func, default_period]).to describe_current_timeset
      tester.cycle
    end
    
    it 'can switch back to an existing timeset without supplying the period_in_ns argument' do
      tester.cycle
      expect(tester.timeset.period_in_ns).to be(default_period)

      tester.set_timeset("func2", updated_period)
      expect([:func2, updated_period]).to describe_current_timeset
      tester.cycle

      tester.set_timeset("func")
      expect([:func, default_period]).to describe_current_timeset
      tester.cycle

      tester.set_timeset("func2")
      expect([:func2, updated_period]).to describe_current_timeset
      tester.cycle
    end
    
    it 'can freely change the period_in_ns provide the timeset has not been cycled yet' do
      expect([:func, default_period]).to describe_current_timeset
      tester.set_timeset('func', updated_period)
      expect([:func, updated_period]).to describe_current_timeset
    end
    
    after(:all) do
      # Switch back to the original target
      Origen.environment.temporary = nil
      Origen.load_target(@old_target)
    end
  end

  describe 'Complex timing' do
    context 'without a default period_in_ns set' do

      before(:context) do
        # Save the current target
        @old_target = "#{Origen.target.name}.rb"
      end
      
      before(:each) do
        Origen.environment.temporary = "j750.rb"
        Origen.load_target("dut.rb")
        expect(dut.current_timeset_period).to be(nil)
        
        # Add the complex timeset
        expect(dut.timesets).to_not include(:complex_timing)
        dut.add_timeset(:complext_timing)
        dut.timeset(:complex_timing) do |t|
          t.drive_wave(:tclk) do |w|
            w.drive(0, at: 0)
            w.drive(:data, at: 'period/2')
          end
        end
        
        expect(dut.timesets).to include(:complex_timing)
      end
      
      it 'does not have a default period in ns' do
        expect(dut.timesets[:complex_timing].period_in_ns).to be(nil)
      end
      
      it 'can set the timeset using a timeset object' do
        tester.set_timeset(dut.timesets[:complex_timing], default_period)
        expect(tester.timeset.period_in_ns).to be(default_period)
        expect(dut.timesets[:complex_timing].period_in_ns).to be(default_period)
        expect(tester.timeset.name).to be(:complex_timing)
      end
      
      it 'raises an error when this timeset is used but a period_in_ns was not set' do
        expect {
          tester.set_timeset(:complex_timing)
        }.to raise_error(RuntimeError, /You must supply a period_in_ns argument to set_timeset/)
        expect(dut.timesets[:complex_timing].period_in_ns).to be(nil)
      end
      
      it 'can set the period_in_ns to be set directly, allowing set_timest to be used without a period_in_ns, and updating the DUT\'s timeset' do
        tester.set_timeset(:complex_timing, default_period)
        expect([:complex_timing, default_period]).to describe_current_timeset

        tester.set_timeset(:complex_timing, updated_period)
        expect([:complex_timing, updated_period]).to describe_current_timeset
      end

      it 'allows the period_in_ns to be set directly, then allowing #set_timeset to be used without a period_in_ns' do
        dut.timesets[:complex_timing].period_in_ns = updated_period
        expect(dut.timesets[:complex_timing].period_in_ns).to eql(updated_period)
        expect(tester.timeset).to be(nil)

        tester.set_timeset(:complex_timing)
        expect([:complex_timing, updated_period]).to describe_current_timeset
      end
      
      it 'raises in an error if the period_in_ns is changed after this timeset has been cycled' do
        tester.set_timeset(:complex_timing, default_period)
        tester.cycle
        
        expect {
          tester.set_timeset(:complex_timing, updated_period)
        }.to raise_error(OrigenTesters::Timing::InvalidModification, /Timeset :complex_timing's period_in_ns cannot be changed after a cycle has occurred using this timeset!/) 
        expect([:complex_timing, default_period]).to describe_current_timeset

        expect {
          tester.timeset.period_in_ns = updated_period
        }.to raise_error(OrigenTesters::Timing::InvalidModification, /Timeset :complex_timing's period_in_ns cannot be changed after a cycle has occurred using this timeset!/) 
        expect([:complex_timing, default_period]).to describe_current_timeset

        expect {
          dut.timesets[:complex_timing].period_in_ns = updated_period
        }.to raise_error(OrigenTesters::Timing::InvalidModification, /Timeset :complex_timing's period_in_ns cannot be changed after a cycle has occurred using this timeset!/) 
        expect([:complex_timing, default_period]).to describe_current_timeset
      end
      
      after(:context) do
        # Switch back to the original target
        Origen.environment.temporary = nil
        Origen.load_target(@old_target)
      end
    end
    
    context 'with a default period_in_ns set' do

      before(:context) do
        # Save the current target
        @old_target = "#{Origen.target.name}.rb"
      end
      
      before(:each) do
        Origen.environment.temporary = "j750.rb"
        Origen.load_target("dut.rb")
        expect(dut.current_timeset_period).to be(nil)
        
        # Add the complex timeset
        expect(dut.timesets).to_not include(:complex_timing)
        dut.add_timeset(:complex_timing)
        dut.timeset(:complex_timing) do |t|
          t.period_in_ns = default_period
          t.drive_wave(:tclk) do |w|
            w.drive(0, at: 0)
            w.drive(:data, at: 'period/2')
          end
        end
        
        expect(dut.timesets).to include(:complex_timing)
        expect(dut.timesets[:complex_timing].period_in_ns).to eql(default_period)
      end
      
      it 'does have a default period in ns' do
        expect(dut.timesets[:complex_timing].period_in_ns).to eql(default_period)
      end
      
      it 'can be set as the timeset without specifying a period_in_ns' do
        tester.set_timeset(:complex_timing)
        expect([:complex_timing, default_period]).to describe_current_timeset
      end

      it 'allows changes to the period_in_ns, and is reflected in the DUT\'s timeset' do
        tester.set_timeset(:complex_timing)
        dut.timesets[:complex_timing].period_in_ns = updated_period
        expect(dut.timesets[:complex_timing].period_in_ns).to eql(updated_period)
      end

      it 'allows changes to the period_in_ns, and is reflected in the DUT\'s timeset, and in the tester' do
        tester.set_timeset(:complex_timing)
        expect([:complex_timing, default_period]).to describe_current_timeset

        dut.timesets[:complex_timing].period_in_ns = updated_period
        expect([:complex_timing, updated_period]).to describe_current_timeset
      end
     
      it 'allows changes to the period_in_ns from #set_timest, and is reflected in the DUT\'s timeset' do
        tester.set_timeset(:complex_timing, updated_period)
        expect([:complex_timing, updated_period]).to describe_current_timeset
      end
      
      it 'raises in an error if the period_in_ns is changed after this timeset has been cycled' do
        tester.set_timeset(:complex_timing)
        tester.cycle
        
        expect {
          tester.set_timeset(:complex_timing, updated_period)
        }.to raise_error(OrigenTesters::Timing::InvalidModification, /Timeset :complex_timing's period_in_ns cannot be changed after a cycle has occurred using this timeset!/) 
        expect([:complex_timing, default_period]).to describe_current_timeset

        expect {
          tester.timeset.period_in_ns = updated_period
        }.to raise_error(OrigenTesters::Timing::InvalidModification, /Timeset :complex_timing's period_in_ns cannot be changed after a cycle has occurred using this timeset!/) 
        expect([:complex_timing, default_period]).to describe_current_timeset

        expect {
          dut.timesets[:complex_timing].period_in_ns = updated_period
        }.to raise_error(OrigenTesters::Timing::InvalidModification, /Timeset :complex_timing's period_in_ns cannot be changed after a cycle has occurred using this timeset!/) 
        expect([:complex_timing, default_period]).to describe_current_timeset
      end
      
      it 'can be manipulated without being the active timeset' do
        # Set the timeset as some other timeset
        tester.set_timeset(:func, 10)
        expect(tester.timeset.name.to_sym).to eql(:func)
        expect(tester.timeset.period_in_ns).to eql(10)
        expect(dut.current_timeset_period).to eql(10)

        # Adjust the period from the DUT side
        expect(dut.timesets[:complex_timing].period_in_ns).to eql(default_period)
        dut.timesets[:complex_timing].period_in_ns = updated_period
        expect(dut.timesets[:complex_timing].period_in_ns).to eql(updated_period)
        expect(tester.timesets[:complex_timing].period_in_ns).to eql(updated_period)

        # Adjusting the timeset shouldn't have any effect on the current timeset.
        expect(tester.timeset.name.to_sym).to eql(:func)
        expect(tester.timeset.period_in_ns).to eql(10)
        expect(dut.current_timeset_period).to eql(10)

        # Adjust the timeset from the tester side
        dut.timesets[:complex_timing].period_in_ns = updated_period + 1
        expect(dut.timesets[:complex_timing].period_in_ns).to eql(updated_period + 1)
        expect(tester.timesets[:complex_timing].period_in_ns).to eql(updated_period + 1)

        # Adjusting the timeset shouldn't have any effect on the current timeset.
        expect(tester.timeset.name.to_sym).to eql(:func)
        expect(tester.timeset.period_in_ns).to eql(10)
        expect(dut.current_timeset_period).to eql(10)
      end
      
      it 'knows if it is the current timeset' do
        expect(dut.timesets[:complex_timing].current_timeset?).to be(false)
        expect(tester.timesets[:complex_timing].current_timeset?).to be(false)
        tester.set_timeset(:complex_timing)
        expect(dut.timesets[:complex_timing].current_timeset?).to be(true)
        expect(tester.timesets[:complex_timing].current_timeset?).to be(true)

        tester.set_timeset(:func, updated_period)
        expect(tester.timesets[:func].current_timeset?).to be(true)
        expect(dut.timesets[:complex_timing].current_timeset?).to be(false)
        expect(tester.timesets[:complex_timing].current_timeset?).to be(false)
      end
      
      it 'knows if it has been called' do
        expect(dut.timesets[:complex_timing].called?).to be(false)
        tester.set_timeset(:complex_timing, default_period)
        expect(dut.timesets[:complex_timing].called?).to be(true)
      end
      
      it 'knowns if it has been cycled' do
        tester.set_timeset(:complex_timing)
        expect(tester.timeset.cycled?).to be(false)
        expect(dut.timesets[:complex_timing].cycled?).to be(false)

        tester.cycle
        expect(tester.timeset.cycled?).to be(true)
        expect(dut.timesets[:complex_timing].cycled?).to be(true)
      end
      
      after(:context) do
        # Switch back to the original target
        Origen.environment.temporary = nil
        Origen.load_target(@old_target)
      end
    end

    context 'with a default period_in_ns set and locked' do
      let(:lock_message) { /Timeset :complex_timing's period_in_ns is locked to #{default_period} ns!/ }

      before(:context) do
        # Save the current target
        @old_target = "#{Origen.target.name}.rb"
      end
      
      before(:each) do
        Origen.environment.temporary = "j750.rb"
        Origen.load_target("dut.rb")
        expect(dut.current_timeset_period).to be(nil)
        
        # Add the complex timeset
        # Add the complex timeset
        expect(dut.timesets).to_not include(:complex_timing)
        dut.add_timeset(:complex_timing)
        dut.timeset(:complex_timing) do |t|
          t.period_in_ns = 1
          t.lock_period!
          t.drive_wave(:tclk) do |w|
            w.drive(0, at: 0)
            w.drive(:data, at: 'period/2')
          end
        end
        expect(dut.timesets[:complex_timing].locked?).to be(true)
        expect(tester.timesets[:complex_timing].locked?).to be(true)
      end
      
      it 'has a default period in ns' do
        expect(dut.timesets[:complex_timing].period_in_ns).to eql(default_period)
      end
      
      it 'can be set as the timeset without specifying a period_in_ns' do
        tester.set_timeset(:complex_timing)
        expect([:complex_timing, default_period]).to describe_current_timeset
      end
      
      it 'does not allow the period_in_ns to be changed, even if it has not been cycled' do
        tester.set_timeset(:complex_timing)
        expect(tester.timeset.cycled?).to be(false)
        
        expect {
          tester.set_timeset(:complex_timing, updated_period)
        }.to raise_error(OrigenTesters::Timing::InvalidModification, lock_message)
        expect([:complex_timing, default_period]).to describe_current_timeset

        expect {
          tester.timeset.period_in_ns = updated_period
        }.to raise_error(OrigenTesters::Timing::InvalidModification, lock_message)
        expect([:complex_timing, default_period]).to describe_current_timeset

        expect {
          dut.timesets[:complex_timing].period_in_ns = updated_period
        }.to raise_error(OrigenTesters::Timing::InvalidModification, lock_message)
        expect([:complex_timing, default_period]).to describe_current_timeset
      end
      
      # Note: since the period_in_ns cannot be changed at all, attempts to change it
      # during the course of the pattern will fail, but they'll fail with the message
      # regarding locked timesets.
      
      after(:context) do
        # Switch back to the original target
        Origen.environment.temporary = nil
        Origen.load_target(@old_target)
      end
    end
  end

  before(:each) do
    Origen.environment.temporary = "j750.rb"
    Origen.load_target("dut.rb")
    expect(dut.current_timeset_period).to be(nil)
    
    @old = Origen.instance_variable_get(:@debug)
    Origen.instance_variable_set(:@debug, true)
  end

  it 'keeps track of the called timesets (legacy - by instance)' do
    expect(tester.called_timesets).to be_empty
    timesets = []
    
    timesets << tester.set_timeset(:func, default_period)
    expect(tester.called_timesets).to eql(timesets)
    
    timesets << tester.set_timeset(:func2, default_period)
    expect(tester.called_timesets).to eql(timesets)
    
    expect(tester.method(:called_timesets)).to eql(tester.method(:called_timesets_by_instance))
  end
  
  it 'keeps track of the called timesets by name' do
    expect(tester.called_timesets).to be_empty
    timesets = ['func']
    
    tester.set_timeset(:func, default_period)
    expect(tester.called_timesets_by_name).to eql(timesets)
    
    timesets << 'func2'
    tester.set_timeset(:func2, default_period)
    expect(tester.called_timesets_by_name).to eql(timesets)
  end

  it 'can run a block as a temporary timeset' do
    tester.set_timeset(:func, default_period)
    expect([:func, default_period]).to describe_current_timeset

    tester.set_timeset(:func2, updated_period) do
      expect([:func2, updated_period]).to describe_current_timeset
    end
    expect([:func, default_period]).to describe_current_timeset

    tester.with_timeset(:func2, updated_period) do
      expect([:func2, updated_period]).to describe_current_timeset
    end
    expect([:func, default_period]).to describe_current_timeset
  end

  it 'allows changes from dut.current_timeset_period=' do
    tester.set_timeset(:func, default_period)
    expect([:func, default_period]).to describe_current_timeset
    
    dut.current_timeset_period = updated_period
    expect([:func, updated_period]).to describe_current_timeset
  end

  it 'raises an error if the current timeset has not yet been defined' do
    expect(tester.timeset).to be(nil)
    expect {
      dut.current_timeset_period = default_period
    }.to raise_error(
      OrigenTesters::Timing::InvalidModification,
      /No current timeset has been defined! Cannot update the current timeset period!/
    )
  end
  
  it 'allows current timeset changes from dut.current_timeset=' do
    tester.set_timeset(:func, default_period)
    expect([:func, default_period]).to describe_current_timeset
    
    dut.timeset(:func2) do |t|
      t.period_in_ns = updated_period
    end
    dut.current_timeset = :func2
    expect([:func2, updated_period]).to describe_current_timeset
  end
  
  it 'links with its corresponding tester timeset' do
    dut.timeset(:func) { }
    expect(dut.timesets[:func]._timeset_).to be_a(OrigenTesters::Timing::Timeset)
    expect(dut.timesets[:func]._timeset_.name).to eql(:func)
  end
  
  it 'raises an error if dut.current_timeset= uses an undefined timeset' do
    expect {
      dut.current_timeset = :func
    }.to raise_error(RuntimeError, /No timeset :func has been defined yet! Please define this timeset or use tester.set_timeset/)
  end
  
  after(:all) do
    Origen.instance_variable_set(:@debug, @old)
  end

end

