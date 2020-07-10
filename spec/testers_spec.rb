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

  it "select SmartTest SMT7 tester properly" do
    Origen.environment.temporary = "v93k.rb"
    Origen.load_target("dut.rb")
    $tester.name.should == "v93k"
    $tester.program_comment_char == '--'
  end

  it "select SmartTest SMT8 tester properly" do
    Origen.environment.temporary = "v93k_smt8.rb"
    Origen.load_target("dut.rb")
    $tester.name.should == "v93k"
    $tester.program_comment_char == '//'
  end
end
