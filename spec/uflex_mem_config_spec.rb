require 'spec_helper'

describe "Uflex configure source and capture memory" do

  it "defaults to digsrc for overlay, digcap for store" do
    Origen.environment.temporary = "uflex.rb"
    Origen.load_target("dut")
    $tester.overlay_style.should == :digsrc
    $tester.capture_style.should == :digcap
  end

  it "can be configured to non-default styles" do
    Origen.environment.temporary = "uflex.rb"
    Origen.load_target("dut")
    $tester.overlay_style = :label
    $tester.capture_style = :hram
    $tester.overlay_style.should == :label
    $tester.capture_style.should == :hram
  end
  
  it "can configure non-default source/capture memory settings" do
    Origen.environment.temporary = "uflex.rb"
    Origen.load_target("dut")
    $tester.source_memory :digsrc do |mem|
      mem.pin :tdi, size: 32
      mem.pin :other, trigger: :none
    end
    $tester.capture_memory :digcap do |mem|
      mem.pin :tdo, size: 8
    end
    
    $tester.source_memory(:digsrc).accumulate_attributes(:tdi).should == {pin_id: :tdi, size: 32, bit_order: nil, format: nil, trigger: nil}
    $tester.source_memory(:digsrc).accumulate_attributes(:other).should == {pin_id: :other, size: nil, bit_order: nil, format: nil, trigger: :none}
    $tester.capture_memory(:digcap).accumulate_attributes(:tdo).should == {pin_id: :tdo, size: 8, bit_order: nil, format: nil, trigger: nil}
  end

end
