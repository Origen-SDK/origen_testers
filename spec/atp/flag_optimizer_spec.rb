require 'spec_helper'

describe 'The flag optimizer' do

  include OrigenTesters::ATP::FlowAPI

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  def ast(options = {})
    options = {
      optimization: :smt,
      add_ids: false,
      implement_continue: false
    }.merge(options)
    atp.ast(options)
  end

  it "works at the top-level" do
    test :test1, id: :t1 
    test :test2, if_failed: :t1

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1"),
          s(:dependent_types, {"failed"=>true}),
          s(:on_fail,
            s(:continue),
            s(:test,
              s(:object, "test2")))))
  end

  it "doesn't eliminate flags with later references" do
    test :test1, id: :t1
    test :test2, if_failed: :t1
    test :test3
    test :test4, if_failed: :t1

    ast.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1"),
          s(:dependent_types, {"failed"=>true}),
          s(:on_fail,
            s(:set_flag, "t1_FAILED", "auto_generated"),
            s(:continue),
            s(:test,
              s(:object, "test2")))),
        s(:test,
          s(:object, "test3")),
        s(:if_flag, "t1_FAILED",
          s(:test,
            s(:object, "test4"))))
  end

  it "applies the optimization within nested groups" do
    group :group1 do
      test :test1, id: :t1
      test :test2, if_failed: :t1
    end

    ast.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "group1"),
          s(:test,
            s(:object, "test1"),
            s(:id, "t1"),
            s(:dependent_types, {"failed"=>true}),
            s(:on_fail,
              s(:continue),
              s(:test,
                s(:object, "test2"))))))
  end

  it "a more complex test case with both pass and fail branches to be optimized" do
    test :test1, id: :t1, number: 0
    test :test2, if_passed: :t1, number: 0
    test :test3, if_failed: :t1, number: 0
    bin 10, if_failed: :t1
      
    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:number, 0),
          s(:id, "t1"),
          s(:dependent_types, {"passed"=>true, "failed"=>true}),
          s(:on_pass,
            s(:test,
              s(:object, "test2"),
              s(:number, 0))),
          s(:on_fail,
            s(:continue),
            s(:test,
              s(:object, "test3"),
              s(:number, 0)),
            s(:set_result, "fail",
              s(:bin, 10)))))
  end

  it "optionally doesn't eliminate flags on tests with a continue" do
    test :test1, id: :t1
    test :test2, if_failed: :t1

    ast(optimize_flags_when_continue: false).should == 
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1"),
          s(:dependent_types, {"failed"=>true}),
          s(:on_fail,
            s(:set_flag, "t1_FAILED", "auto_generated"),
            s(:continue))),
        s(:if_flag, "t1_FAILED",
          s(:test,
            s(:object, "test2"))))
  end

end
