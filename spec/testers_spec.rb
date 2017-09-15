require 'spec_helper'

describe "IGXL Based Tester class" do

  it "select J750 tester properly" do
    Origen.environment.temporary = "j750.rb"
    Origen.load_target("dut.rb")
    $tester.name.should == "j750"
    $tester.respond_to?('hpt_mode').should == false
  end

  it "select J750 HPT tester properly" do
    Origen.environment.temporary = "j750_hpt.rb"
    Origen.load_target("dut.rb")
    $tester.name.should == "j750_hpt"
    $tester.class.hpt_mode.should == true
  end

  it "select UltraFLEX tester properly" do
    Origen.environment.temporary = "uflex.rb"
    Origen.load_target("dut.rb")
    $tester.name.should == "ultraflex"
  end

end
