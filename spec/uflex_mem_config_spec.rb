require 'spec_helper'

describe "Uflex configure source and capture memory" do
  class UFlexMemConfigDUT
    include Origen::TopLevel
    def initialize
      add_pin :tdi
      add_pin :other
      add_pin :tdo
    end
  end

  it "defaults to digsrc for overlay, digcap for store" do
    Origen.target.temporary = -> { UFlexMemConfigDUT.new; OrigenTesters::UltraFLEX.new }
    Origen.target.load!
    $tester.overlay_style.should == :digsrc
    $tester.capture_style.should == :digcap
  end

  it "can be configured to non-default styles" do
    Origen.target.temporary = -> { UFlexMemConfigDUT.new; OrigenTesters::UltraFLEX.new }
    Origen.target.load!
    $tester.overlay_style = :label
    $tester.capture_style = :hram
    $tester.overlay_style.should == :label
    $tester.capture_style.should == :hram
  end
  
  it "can configure non-default source/capture memory settings" do
    Origen.target.temporary = -> { UFlexMemConfigDUT.new; OrigenTesters::UltraFLEX.new }
    Origen.target.load!
    $tester.source_memory :digsrc do |mem|
      mem.pin :tdi, size: 32
      mem.pin :other, trigger: :none
    end
    $tester.capture_memory :digcap do |mem|
      mem.pin :tdo, size: 8
    end
    
    $tester.source_memory(:digsrc).accumulate_attributes(:tdi)[:size].should == 32
    $tester.source_memory(:digsrc).accumulate_attributes(:other)[:trigger].should == :none
    $tester.capture_memory(:digcap).accumulate_attributes(:tdo)[:size].should == 8
  end

end
