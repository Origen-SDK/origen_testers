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
        s(:loop, 0.3, 0.4, 0.1, nil, 1,
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
        s(:set, "vol", 0),
        s(:loop, 0.3, 0.4, 0.1, "vol", 1,
          s(:test,
            s(:object, "test_loop1"))),
        s(:test,
          s(:object, "test_post_loop")))
  end

  it "can cede to ruby loop keyword" do
    test :test_pre_loop
    id = 1
    loop do
      test "test_loop#{id}".to_sym
      id += 1
      break if id > 3
    end
    atp.raw.should ==
    s(:flow,
      s(:name, "sort1"),
      s(:test,
        s(:object, "test_pre_loop")),
          s(:test,
            s(:object, "test_loop1")),
          s(:test,
            s(:object, "test_loop2")),
          s(:test,
            s(:object, "test_loop3")))
  end
end


