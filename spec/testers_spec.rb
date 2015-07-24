require 'spec_helper'

describe "IGXL Based Tester class" do

  it "select J750 tester properly" do
    RGen.target.temporary = "debug_j750.rb"
    RGen.target.load!
    $tester.name.should == "j750"
    $tester.respond_to?('hpt_mode').should == false
  end

  it "select J750 HPT tester properly" do
    RGen.target.temporary = "debug_j750_hpt.rb"
    RGen.target.load!
    $tester.name.should == "j750_hpt"
    $tester.class.hpt_mode.should == true
  end

  it "select UltrFLEX tester properly" do
    RGen.target.temporary = "debug_ultraflex.rb"
    RGen.target.load!
    $tester.name.should == "ultraflex"
  end

end
