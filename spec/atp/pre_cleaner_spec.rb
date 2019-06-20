require 'spec_helper'

describe 'The Pre Cleaner' do
  include OrigenTesters::ATP::FlowAPI

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  def ast
    atp.ast(apply_relationships: false, add_ids: false)
  end

  it "lower cases all IDs and references" do
    test :test1, id: "T1"
    group :G1, id: "G1" do
      test :test2, id: "T2"
    end
    test :test3, if_failed: "T1"
    test :test4, if_any_failed: ["T1", "T2"]

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "T1")),
        s(:group,
          s(:name, "G1"),
          s(:id, "G1"),
          s(:test,
            s(:object, "test2"),
            s(:id, "T2"))),
        s(:if_failed, "T1",
          s(:test,
            s(:object, "test3"))),
        s(:if_any_failed, ["T1", "T2"],
          s(:test,
            s(:object, "test4"))))

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1")),
        s(:group,
          s(:name, "G1"),
          s(:id, "g1"),
          s(:test,
            s(:object, "test2"),
            s(:id, "t2"))),
        s(:if_failed, "t1",
          s(:test,
            s(:object, "test3"))),
        s(:if_any_failed, ["t1", "t2"],
          s(:test,
            s(:object, "test4"))))
  end

  it "removes test ID assigments that refer to the parent group" do
    group :G1, id: "G1" do
      test :test1, id: "G1"
      test :test2, id: "G1"
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "G1"),
          s(:id, "G1"),
          s(:test,
            s(:object, "test1"),
            s(:id, "G1")),
          s(:test,
            s(:object, "test2"),
            s(:id, "G1"))))
    
    ast.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "G1"),
          s(:id, "g1"),
          s(:test,
            s(:object, "test1")),
          s(:test,
            s(:object, "test2"))))

  end
end
