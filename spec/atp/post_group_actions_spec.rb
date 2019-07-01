require 'spec_helper'

describe 'The post group action applier' do
  include OrigenTesters::ATP::FlowAPI

  def ast(options = {})
    options = {
      optimization: :igxl,
      add_ids: false,
      one_flag_per_test: false,
    }.merge(options)
    atp.ast(options)
  end

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  it "applies the groups actions to all contained tests" do
    group "outer", id: :g1 do
      test :test1
      group "inner" do
        test :test2
      end
    end
    test :test3, if_failed: :g1

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "outer"),
          s(:id, "g1"),
          s(:test,
            s(:object, "test1")),
          s(:group,
            s(:name, "inner"),
            s(:test,
              s(:object, "test2")))),
        s(:if_failed, "g1",
          s(:test,
            s(:object, "test3"))))

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "outer"),
          s(:id, "g1"),
          s(:test,
            s(:object, "test1"),
            s(:on_fail,
              s(:set_flag, "g1_FAILED", "auto_generated"),
              s(:continue))),
          s(:group,
            s(:name, "inner"),
            s(:test,
              s(:object, "test2"),
              s(:on_fail,
                s(:set_flag, "g1_FAILED", "auto_generated"),
                s(:continue)))),
          s(:dependent_types, {"failed"=>true})),
        s(:if_flag, "g1_FAILED",
          s(:test,
            s(:object, "test3"))))
  end

  it "applies an optional Teradyne optimization to only set flags once per test result" do
    group "outer", id: :g1 do
      test :test1
      group "inner" do
        test :test2
      end
    end
    test :test3, if_failed: :g1
    test :test4, if_passed: :g1

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "outer"),
          s(:id, "g1"),
          s(:test,
            s(:object, "test1"),
            s(:on_pass,
              s(:set_flag, "g1_PASSED", "auto_generated")),
            s(:on_fail,
              s(:continue),
              s(:set_flag, "g1_FAILED", "auto_generated"))),
          s(:group,
            s(:name, "inner"),
            s(:test,
              s(:object, "test2"),
              s(:on_pass,
                s(:set_flag, "g1_PASSED", "auto_generated")),
              s(:on_fail,
                s(:continue),
                s(:set_flag, "g1_FAILED", "auto_generated")))),
          s(:dependent_types, {"failed"=>true, "passed"=>true})),
        s(:if_flag, "g1_FAILED",
          s(:test,
            s(:object, "test3"))),
        s(:if_flag, "g1_PASSED",
          s(:test,
            s(:object, "test4"))))


    ast(one_flag_per_test: true).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "outer"),
          s(:id, "g1"),
          s(:test,
            s(:object, "test1"),
            s(:on_fail,
              s(:continue),
              s(:set_flag, "g1_FAILED_0", "auto_generated")),
            s(:on_pass,
              s(:set_flag, "g1_PASSED_0", "auto_generated"))),
          s(:if_flag, "g1_FAILED_0",
            s(:set_flag, "g1_FAILED", "auto_generated")),
          s(:if_flag, "g1_PASSED_0",
            s(:set_flag, "g1_PASSED", "auto_generated")),
          s(:group,
            s(:name, "inner"),
            s(:test,
              s(:object, "test2"),
              s(:on_fail,
                s(:continue),
                s(:set_flag, "g1_FAILED_1", "auto_generated")),
              s(:on_pass,
                s(:set_flag, "g1_PASSED_1", "auto_generated"))),
            s(:if_flag, "g1_FAILED_1",
              s(:set_flag, "g1_FAILED", "auto_generated")),
            s(:if_flag, "g1_PASSED_1",
              s(:set_flag, "g1_PASSED", "auto_generated"))),
          s(:dependent_types, {"failed"=>true, "passed"=>true})),
        s(:if_flag, "g1_FAILED",
          s(:test,
            s(:object, "test3"))),
        s(:if_flag, "g1_PASSED",
          s(:test,
            s(:object, "test4"))))
  end
end
