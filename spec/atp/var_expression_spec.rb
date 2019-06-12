require 'spec_helper'

describe 'Variable Expressions' do
  include OrigenTesters::ATP::FlowAPI

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  it "can create whenever node(s)" do
    whenever eq('ONE', 1) do
      test :test_1eq1
    end
    whenever le('TWO', 3) do
      test :test_2le3
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:whenever, [s(:eq, "ONE", 1)],
          s(:test,
            s(:object, "test_1eq1"))),
        s(:whenever, [s(:le, "TWO", 3)],
          s(:test,
            s(:object, "test_2le3"))))
  end

  it "can create whenever_all node" do
    whenever_all gt('FOUR', 2), ne('FIVE', 6) do
      test :test_4gt2and5ne6
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:whenever_all, [s(:gt, "FOUR", 2), s(:ne, "FIVE", 6)],
          s(:test,
            s(:object, "test_4gt2and5ne6"))))
  end

  it "can create whenever_any node" do
    whenever_any ge('SEVEN', 0), lt('EIGHT', 9) do
      test :test_7ge0or8lt9
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:whenever_any, [s(:ge, "SEVEN", 0), s(:lt, "EIGHT", 9)],
          s(:test,
            s(:object, "test_7ge0or8lt9"))))
  end

  it "can create set node" do
    set 'ONE', 0

    whenever eq('ONE', 1) do
      test :test_1eq1
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:set, "ONE", 0),
        s(:whenever, [s(:eq, "ONE", 1)],
          s(:test,
            s(:object, "test_1eq1"))))
  end
end

