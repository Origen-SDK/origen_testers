require 'spec_helper'

describe 'The base processor' do
  include OrigenTesters::ATP::FlowAPI

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  it "returns the same AST" do
    test :test1, on_fail: { bin: 5 }
    test :test2, on_fail: { bin: 6, continue: true }
    OrigenTesters::ATP::Processor.new.process(atp.raw).should == atp.raw
  end

  #it "finds IDs of tests that have dependents" do
  #  flow = OrigenTesters::ATP::Program.new.flow(:sort1) 
  #  atp.test :test1, on_fail: { bin: 5 }, id: :t1
  #  atp.test :test2, on_fail: { bin: 5 }, id: :t2
  #  atp.test :test3, on_fail: { bin: 5 }, id: :t3, if_failed: :t2
  #  atp.test :test4, on_fail: { bin: 5 }, id: :t4, if_failed: :t2
  #  atp.test :test5, on_fail: { bin: 5 }, id: :t5
  #  atp.test :test6, on_fail: { bin: 5 }, id: :t6, if_failed: :t4
  #  p = OrigenTesters::ATP::Processor.new
  #  p.process(atp.raw)
  #  p.tests_with_dependents.should == [:t2, :t4]
  #end
end
