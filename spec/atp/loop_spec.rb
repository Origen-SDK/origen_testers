require 'spec_helper'

describe 'Loop Support' do
  include OrigenTesters::ATP::FlowAPI

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  it "can create loop without variable specified" do
    test :test_pre_loop
    loop from: 0.3, to: 0.4, step: 0.1 do
      test :test_loop1
    end
    test :test_post_loop
    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test_pre_loop")),
        s(:loop, 0.3, 0.4, 0.1, nil,
          s(:test,
            s(:object, "test_loop1"))),
        s(:test,
          s(:object, "test_post_loop")))
  end

  it "can create loop with variable specified" do
    test :test_pre_loop
    loop from: 0.3, to: 0.4, step: 0.1, var: "vol" do
      test :test_loop1
    end
    test :test_post_loop
    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test_pre_loop")),
        s(:loop, 0.3, 0.4, 0.1, "vol",
          s(:test,
            s(:object, "test_loop1"))),
        s(:test,
          s(:object, "test_post_loop")))
  end
end


