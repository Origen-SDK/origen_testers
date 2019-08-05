require 'spec_helper'

describe 'The Relationship Processor' do
  include OrigenTesters::ATP::FlowAPI

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  def ast(options = {})
    options = {
      optimization: :smt,
      add_ids: false,
      implement_continue: false,
    }.merge(options)
    atp.ast(options)
  end

  it "updates both sides of the relationship" do
    test :test1, id: :t1
    test :test2, id: :t2, bin: 10
    test :test3, if_passed: :t1
    test :test4, if_passed: :t2
    test :test5, if_failed: :t2

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1)),
        s(:test,
          s(:object, "test2"),
          s(:id, :t2),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 10)))),
        s(:if_passed, :t1,
          s(:test,
            s(:object, "test3"))),
        s(:if_passed, :t2,
          s(:test,
            s(:object, "test4"))),
        s(:if_failed, :t2,
          s(:test,
            s(:object, "test5"))))

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1),
          s(:on_pass,
            s(:set_flag, "t1_PASSED", "auto_generated")),
          s(:on_fail,
            s(:continue))),
        s(:test,
          s(:object, "test2"),
          s(:id, :t2),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 10)),
            s(:continue),
            s(:set_flag, "t2_FAILED", "auto_generated")),
          s(:on_pass,
            s(:set_flag, "t2_PASSED", "auto_generated"))),
        s(:if_flag, "t1_PASSED",
          s(:test,
            s(:object, "test3"))),
        s(:if_flag, "t2_PASSED",
          s(:test,
            s(:object, "test4"))),
        s(:if_flag, "t2_FAILED",
          s(:test,
            s(:object, "test5"))))
  end

  it "embedded test results are processed" do
    test :test1, id: :ect1_1
    if_failed :ect1_1 do
      test :test2
      test :test3, id: :ect1_3
      test :test4, if_failed: :ect1_3
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ect1_1")),
        s(:if_failed, "ect1_1",
          s(:test,
            s(:object, "test2")),
          s(:test,
            s(:object, "test3"),
            s(:id, "ect1_3")),
          s(:if_failed, "ect1_3",
            s(:test,
              s(:object, "test4")))))

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ect1_1"),
          s(:on_fail,
            s(:continue),
            s(:test,
              s(:object, "test2")),
            s(:test,
              s(:object, "test3"),
              s(:id, "ect1_3"),
              s(:on_fail,
                s(:continue),
                s(:test,
                  s(:object, "test4")))))))
  end

  it "any failed is processed" do
    test :test1, id: :t1
    test :test2, id: :t2
    test :test3, if_any_failed: [:t1, :t2]

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "t2")),
        s(:if_any_failed, [:t1, :t2],
          s(:test,
            s(:object, "test3"))))

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1"),
          s(:on_fail,
            s(:set_flag, "t1_FAILED", "auto_generated"),
            s(:continue))),
        s(:test,
          s(:object, "test2"),
          s(:id, "t2"),
          s(:on_fail,
            s(:set_flag, "t2_FAILED", "auto_generated"),
            s(:continue))),
        s(:if_flag, ["t1_FAILED", "t2_FAILED"],
          s(:test,
            s(:object,"test3"))))
  end

  it "group-based if_failed is processed" do
    group :group1, id: :grp1 do
      test :test1
      test :test2
    end
    if_failed :grp1 do
      test :test3
      test :test4
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "group1"),
          s(:id, "grp1"),
          s(:test,
            s(:object, "test1")),
          s(:test,
            s(:object, "test2"))),
        s(:if_failed, "grp1",
          s(:test,
            s(:object, "test3")),
          s(:test,
            s(:object, "test4"))))

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "group1"),
          s(:id, "grp1"),
          s(:test,
            s(:object, "test1")),
          s(:test,
            s(:object, "test2")),
          s(:on_fail,
            s(:set_flag, "grp1_FAILED", "auto_generated"),
            s(:continue))),
        s(:if_flag, "grp1_FAILED",
          s(:test,
            s(:object, "test3")),
          s(:test,
            s(:object, "test4"))))
  end

  it "group-based if_passed is processed" do
    group :group1, id: :grp1 do
      test :test1
      test :test2
    end
    if_passed :grp1 do
      group :group2 do
        test :test3
        test :test4
      end
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "group1"),
          s(:id, "grp1"),
          s(:test,
            s(:object, "test1")),
          s(:test,
            s(:object, "test2"))),
        s(:if_passed, "grp1",
          s(:group,
            s(:name, "group2"),
            s(:test,
              s(:object, "test3")),
            s(:test,
              s(:object, "test4")))))

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "group1"),
          s(:id, "grp1"),
          s(:test,
            s(:object, "test1")),
          s(:test,
            s(:object, "test2")),
          s(:on_pass,
            s(:set_flag, "grp1_PASSED", "auto_generated")),
          s(:on_fail,
            s(:continue))),
        s(:if_flag, "grp1_PASSED",
          s(:group,
            s(:name, "group2"),
            s(:test,
              s(:object, "test3")),
            s(:test,
              s(:object, "test4")))))
  end

  it "ran conditions are converted to flag conditions" do
    test :test1, id: :e1
    test :test2, id: :e2
    test :test3, unless_ran: :e1
    if_ran :e2 do
      test :test4
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "e1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "e2")),
        s(:unless_ran, "e1",
          s(:test,
            s(:object, "test3"))),
        s(:if_ran, "e2",
          s(:test,
            s(:object, "test4"))))

    ast.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "e1")),
        s(:set_flag, "e1_RAN", "auto_generated"),
        s(:test,
          s(:object, "test2"),
          s(:id, "e2")),
        s(:set_flag, "e2_RAN", "auto_generated"),
        s(:unless_flag, "e1_RAN",
          s(:test,
            s(:object, "test3"))),
        s(:if_flag, "e2_RAN",
          s(:test,
            s(:object, "test4"))))
  end

  it "should not add continue to the parent test if it is already set to :delayed" do
    test :test1, id: :t1
    test :test2, id: :t2, bin: 10, delayed: true
    test :test3, if_passed: :t1
    test :test4, if_passed: :t2
    test :test5, if_failed: :t2

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1)),
        s(:test,
          s(:object, "test2"),
          s(:id, :t2),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 10)),
            s(:delayed, true))),
        s(:if_passed, :t1,
          s(:test,
            s(:object, "test3"))),
        s(:if_passed, :t2,
          s(:test,
            s(:object, "test4"))),
        s(:if_failed, :t2,
          s(:test,
            s(:object, "test5"))))

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1),
          s(:on_pass,
            s(:set_flag, "t1_PASSED", "auto_generated")),
          s(:on_fail,
            s(:continue))),
        s(:test,
          s(:object, "test2"),
          s(:id, :t2),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 10)),
            s(:delayed, true),
            s(:set_flag, "t2_FAILED", "auto_generated")),
          s(:on_pass,
            s(:set_flag, "t2_PASSED", "auto_generated"))),
        s(:if_flag, "t1_PASSED",
          s(:test,
            s(:object, "test3"))),
        s(:if_flag, "t2_PASSED",
          s(:test,
            s(:object, "test4"))),
        s(:if_flag, "t2_FAILED",
          s(:test,
            s(:object, "test5"))))
  end

  it "if_any_site conditions work" do
    test :test1, id: :t1
    test :test2, id: :t2, bin: 10
    test :test3, if_any_site_passed: :t1
    test :test4, if_all_sites_passed: :t2
    test :test5, if_any_site_failed: :t2

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "t2"),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 10)))),
        s(:if_any_sites_passed, "t1",
          s(:test,
            s(:object, "test3"))),
        s(:if_all_sites_passed, "t2",
          s(:test,
            s(:object, "test4"))),
        s(:if_any_sites_failed, "t2",
          s(:test,
            s(:object, "test5"))))

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1),
          s(:on_pass,
            s(:set_flag, "t1_PASSED", "auto_generated")),
          s(:on_fail,
            s(:continue))),
        s(:test,
          s(:object, "test2"),
          s(:id, :t2),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 10)),
            s(:continue),
            s(:set_flag, "t2_FAILED", "auto_generated")),
          s(:on_pass,
            s(:set_flag, "t2_PASSED", "auto_generated"))),
        s(:if_any_sites_flag, "t1_PASSED",
          s(:test,
            s(:object, "test3"))),
        s(:if_all_sites_flag, "t2_PASSED",
          s(:test,
            s(:object, "test4"))),
        s(:if_any_sites_flag, "t2_FAILED",
          s(:test,
            s(:object, "test5"))))
  end
end
