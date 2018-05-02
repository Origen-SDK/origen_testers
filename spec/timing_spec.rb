require 'spec_helper'

describe "Timing APIs" do

  it "Setting the tester timeset also updates the DUT" do
    Origen.environment.temporary = "j750.rb"
    Origen.load_target("dut.rb")
    dut.current_timeset_period.should == nil
    tester.set_timeset("func", 40)
    dut.current_timeset_period.should == 40
  end
end
