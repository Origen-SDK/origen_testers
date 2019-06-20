require 'spec_helper'

describe 'Sub-flows' do
  include OrigenTesters::ATP::FlowAPI

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  it "can be added to flows" do
    test :test1
    test :test2

    sf = atp.raw
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort2)

    test :test3
    test :test4

    atp.raw.should ==
      s(:flow,
        s(:name, "sort2"),
        s(:test,
          s(:object, "test3")),
        s(:test,
          s(:object, "test4")))

    atp.sub_flow(sf)

    atp.raw.should ==
      s(:flow,
        s(:name, "sort2"),
        s(:test,
          s(:object, "test3")),
        s(:test,
          s(:object, "test4")),
        s(:sub_flow,
          s(:name, "sort1"),
          s(:test,
            s(:object, "test1")),
          s(:test,
            s(:object, "test2"))))
  end

  it "can be removed from flows" do
    test :test1
    test :test2

    sf = atp.raw
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort2)

    test :test3
    test :test4

    atp.sub_flow(sf)

    atp.raw.excluding_sub_flows.should ==
      s(:flow,
        s(:name, "sort2"),
        s(:test,
          s(:object, "test3")),
        s(:test,
          s(:object, "test4")))
  end
end
