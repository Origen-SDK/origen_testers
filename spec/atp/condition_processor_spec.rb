require 'spec_helper'

describe 'The Condition Processor' do
  include OrigenTesters::ATP::FlowAPI

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  it "wraps adjacent nodes that share the same conditions" do
    test :test1, id: :t1
    test :test2, if_enabled: "bitmap"
    test :test3, if_enabled: "bitmap", if_failed: :t1

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1)),
        s(:if_enabled, "bitmap",
          s(:test,
            s(:object, "test2"))),
        s(:if_failed, :t1,
          s(:if_enabled, "bitmap",
            s(:test,
              s(:object, "test3")))))

    atp.ast(optimization: :full, apply_relationships: false, add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1)),
        s(:if_enabled, "bitmap",
          s(:test,
            s(:object, "test2")),
          s(:if_failed, :t1,
            s(:test,
              s(:object, "test3")))))
  end

  it "wraps nested conditions" do
    test :test1
    test :test2, if_flag: "bitmap"
    if_flag "bitmap" do
      test :test3, if_flag: "x"
      if_flag "y" do
        test :test4, if_flag: "x"
      end
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1")),
        s(:if_flag, "bitmap",
          s(:test,
            s(:object, "test2"))),
        s(:if_flag, "bitmap",
          s(:if_flag, "x",
            s(:test,
              s(:object, "test3"))),
          s(:if_flag, "y",
            s(:if_flag, "x",
              s(:test,
                s(:object, "test4"))))))

    atp.ast(optimization: :full, apply_relationships: false, add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1")),
        s(:if_flag, "bitmap",
          s(:test,
            s(:object, "test2")),
          s(:if_flag, "x",
            s(:test,
              s(:object, "test3")),
            s(:if_flag, "y",
              s(:test,
                s(:object, "test4"))))))
  end

  it "optimizes groups too" do
    test :test1
    test :test2, group: :g1
    group :g1 do
      group :g2 do
        test :test3
      end
      group :g2 do
        test :test4, group: :g3
      end
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1")),
        s(:group,
          s(:name, "g1"),
          s(:test,
            s(:object, "test2"))),
        s(:group,
          s(:name, "g1"),
          s(:group,
            s(:name, "g2"),
            s(:test,
              s(:object, "test3"))),
          s(:group,
            s(:name, "g2"),
            s(:group,
              s(:name, "g3"),
              s(:test,
                s(:object, "test4"))))))

    atp.ast(optimization: :full, apply_relationships: false, add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1")),
        s(:group,
          s(:name, "g1"),
          s(:test,
            s(:object, "test2")),
          s(:group,
            s(:name, "g2"),
            s(:test,
              s(:object, "test3")),
            s(:group,
              s(:name, "g3"),
              s(:test,
                s(:object, "test4"))))))
  end

  it "combined condition and group test" do
    group :g1 do
      test :test1
      test :test2, if_enable: :bitmap
    end

    if_enable :bitmap do
      group :g1 do
        test :test3, if_flag: :x
        if_flag :y do
          test :test4, if_flag: :x
        end
      end
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "g1"),
          s(:test,
            s(:object, "test1")),
          s(:if_enabled, "bitmap",
            s(:test,
              s(:object, "test2")))),
        s(:if_enabled, "bitmap",
          s(:group,
            s(:name, "g1"),
            s(:if_flag, "x",
              s(:test,
                s(:object, "test3"))),
            s(:if_flag, "y",
              s(:if_flag, "x",
                s(:test,
                  s(:object, "test4")))))))

    atp.ast(optimization: :full, apply_relationships: false, add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "g1"),
          s(:test,
            s(:object, "test1")),
          s(:if_enabled, "bitmap",
            s(:test,
              s(:object, "test2")),
            s(:if_flag, "x",
              s(:test,
                s(:object, "test3")),
              s(:if_flag, "y",
                s(:test,
                  s(:object, "test4")))))))
  end

  it "optimizes jobs" do
    if_job :p1 do
      test :test1
      test :test2, if_enable: :bitmap
    end
    if_enabled :bitmap do
      if_job :p1 do
        test :test3, if_flag: :x
        if_flag :y do
          test :test4, if_flag: :x
        end
      end
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_job, "p1",
          s(:test,
            s(:object, "test1")),
          s(:if_enabled, "bitmap",
            s(:test,
              s(:object, "test2")))),
        s(:if_enabled, "bitmap",
          s(:if_job, "p1",
            s(:if_flag, "x",
              s(:test,
                s(:object, "test3"))),
            s(:if_flag, "y",
              s(:if_flag, "x",
                s(:test,
                  s(:object, "test4")))))))


    atp.ast(optimization: :full, apply_relationships: false, add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_job, "p1",
          s(:test,
            s(:object, "test1")),
          s(:if_enabled, "bitmap",
            s(:test,
              s(:object, "test2")),
            s(:if_flag, "x",
              s(:test,
                s(:object, "test3")),
              s(:if_flag, "y",
                s(:test,
                  s(:object, "test4")))))))
  end

  it "job optimization test 2" do
    test :test1, if_job: ["p1", "p2"]
    test :test2
    test :test3, if_job: ["p1", "p2"]
    test :test4
    test :test5, if_job: ["p1", "p2"]
    test :test6
    test :test7, if_job: ["p1", "p2"]

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test1"))),
        s(:test,
          s(:object, "test2")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test3"))),
        s(:test,
          s(:object, "test4")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test5"))),
        s(:test,
          s(:object, "test6")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test7"))))

    atp.ast(optimization: :full, apply_relationships: false, add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test1"))),
        s(:test,
          s(:object, "test2")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test3"))),
        s(:test,
          s(:object, "test4")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test5"))),
        s(:test,
          s(:object, "test6")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test7"))))
  end

  it "job optimization test 3" do
    test :test1, if_job: ["p1", "p2"]
    test :test2
    test :test3, if_job: ["p1", "p2"]
    test :test4, if_job: ["p1", "p2"]
    test :test5
    test :test6, if_job: ["p1", "p2"]

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test1"))),
        s(:test,
          s(:object, "test2")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test3"))),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test4"))),
        s(:test,
          s(:object, "test5")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test6"))))

    atp.ast(optimization: :full, apply_relationships: false, add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test1"))),
        s(:test,
          s(:object, "test2")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test3")),
          s(:test,
            s(:object, "test4"))),
        s(:test,
          s(:object, "test5")),
        s(:if_job, ["p1", "p2"],
          s(:test,
            s(:object, "test6"))))
  end

  it "test result optimization test" do
    test :test1, id: :ifallb1
    test :test2, id: :ifallb2
    if_failed :ifallb1 do
      test :test3, if_failed: :ifallb2
    end
    if_failed :ifallb2 do
      test :test4, if_failed: :ifallb1
    end
    log "Embedded conditional tests 1"
    test :test1, id: :ect1_1
    test :test2, if_failed: :ect1_1
    test :test3, if_failed: :ect1_1, id: :ect1_3
    if_failed :ect1_3 do
      test :test4, if_failed: :ect1_1
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ifallb1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "ifallb2")),
        s(:if_failed, "ifallb1",
          s(:if_failed, "ifallb2",
            s(:test,
              s(:object, "test3")))),
        s(:if_failed, "ifallb2",
          s(:if_failed, "ifallb1",
            s(:test,
              s(:object, "test4")))),
        s(:log, "Embedded conditional tests 1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ect1_1")),
        s(:if_failed, "ect1_1",
          s(:test,
            s(:object, "test2"))),
        s(:if_failed, "ect1_1",
          s(:test,
            s(:object, "test3"),
            s(:id, "ect1_3"))),
        s(:if_failed, "ect1_3",
          s(:if_failed, "ect1_1",
            s(:test,
              s(:object, "test4")))))

    atp.ast(optimization: :full, apply_relationships: false, add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ifallb1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "ifallb2")),
        s(:if_failed, "ifallb1",
          s(:if_failed, "ifallb2",
            s(:test,
              s(:object, "test3")),
            s(:test,
              s(:object, "test4")))),
        s(:log, "Embedded conditional tests 1"),
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

  end

  it "test result optimization test 2" do
    log "Test that if_any_failed works"
    test :test1, id: :ifa1
    test :test2, id: :ifa2
    test :test3, if_any_failed: [:ifa1, :ifa2]
    log "Test the block form of if_any_failed"
    test :test1, id: :oof_passcode1
    test :test2, id: :oof_passcode2
    if_any_failed [:oof_passcode1, :oof_passcode2] do
      test :test3
    end
    if_any_failed [:oof_passcode1, :oof_passcode2] do
      test :test4
    end

    atp.raw.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:log, "Test that if_any_failed works"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ifa1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "ifa2")),
        s(:if_any_failed, [:ifa1, :ifa2],
          s(:test,
            s(:object, "test3"))),
        s(:log, "Test the block form of if_any_failed"),
        s(:test,
          s(:object, "test1"),
          s(:id, "oof_passcode1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "oof_passcode2")),
        s(:if_any_failed, [:oof_passcode1, :oof_passcode2],
          s(:test,
            s(:object, "test3"))),
        s(:if_any_failed, [:oof_passcode1, :oof_passcode2],
          s(:test,
            s(:object, "test4"))))

    atp.ast(optimization: :full, apply_relationships: false, add_ids: false).should == 
      s(:flow,
        s(:name, "sort1"),
        s(:log, "Test that if_any_failed works"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ifa1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "ifa2")),
        s(:if_any_failed, ["ifa1", "ifa2"],
          s(:test,
            s(:object, "test3"))),
        s(:log, "Test the block form of if_any_failed"),
        s(:test,
          s(:object, "test1"),
          s(:id, "oof_passcode1")),
        s(:test,
          s(:object, "test2"),
          s(:id, "oof_passcode2")),
        s(:if_any_failed, ["oof_passcode1", "oof_passcode2"],
          s(:test,
            s(:object, "test3")),
          s(:test,
            s(:object, "test4"))))
  end

  it "adjacent group optimization test" do
    group "additional_erase" do
      if_flag "additional_erase" do
        test :erase_all, if_job: ["fr"]
      end
    end
    group "additional_erase" do
      test :erase_all, if_job: ["fr"]
    end

    atp.raw.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "additional_erase"),
          s(:if_flag, "additional_erase",
            s(:if_job, ["fr"],
              s(:test,
                s(:object, "erase_all"))))),
        s(:group,
          s(:name, "additional_erase"),
          s(:if_job, ["fr"],
            s(:test,
              s(:object, "erase_all")))))

    atp.ast(optimization: :full, apply_relationships: false, add_ids: false).should == 
      s(:flow,
        s(:name, "sort1"),
        s(:group,
          s(:name, "additional_erase"),
          s(:if_job, ["fr"],
            s(:if_flag, "additional_erase",
                s(:test,
                  s(:object, "erase_all"))),
            s(:test,
              s(:object, "erase_all")))))
  end

  it "Removes duplicate conditions" do
    if_flag :data_collection do
      test :nvm_dist_vcg, if_flag: :data_collection
    end

    atp.raw.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:if_flag, "data_collection",
          s(:if_flag, "data_collection",
            s(:test,
              s(:object, "nvm_dist_vcg")))))

    atp.ast(optimization: :full, apply_relationships: false, add_ids: false).should == 
      s(:flow,
        s(:name, "sort1"),
        s(:if_flag, "data_collection",
          s(:test,
            s(:object, "nvm_dist_vcg"))))
  end

  it "Flags conditions are not optimized when marked as volatile" do
    if_flag "my_flag" do
      test :test1, on_fail: { set_flag: "$My_Mixed_Flag", continue: true }
      test :test2, if_flag: "$My_Mixed_Flag"
      test :test1, if_flag: "my_flag"
      test :test2, if_flag: "my_flag"
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_flag, "my_flag",
          s(:test,
            s(:object, "test1"),
            s(:on_fail,
              s(:set_flag, "$My_Mixed_Flag"),
              s(:continue))),
          s(:if_flag, "$My_Mixed_Flag",
            s(:test,
              s(:object, "test2"))),
          s(:if_flag, "my_flag",
            s(:test,
              s(:object, "test1"))),
          s(:if_flag, "my_flag",
            s(:test,
              s(:object, "test2")))))

    atp.ast(optimization: :full, apply_relationships: false, add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_flag, "my_flag",
          s(:test,
            s(:object, "test1"),
            s(:on_fail,
              s(:set_flag, "$My_Mixed_Flag"),
              s(:continue))),
          s(:if_flag, "$My_Mixed_Flag",
            s(:test,
              s(:object, "test2"))),
          s(:test,
            s(:object, "test1")),
          s(:test,
            s(:object, "test2"))))

    atp.volatile "my_flag", :$my_other_flag

    atp.ast(optimization: :full, apply_relationships: false, add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:volatile,
          s(:flag, "my_flag"),
          s(:flag, "$my_other_flag")),
        s(:if_flag, "my_flag",
          s(:test,
            s(:object, "test1"),
            s(:on_fail,
              s(:set_flag, "$My_Mixed_Flag"),
              s(:continue))),
          s(:if_flag, "$My_Mixed_Flag",
            s(:test,
              s(:object, "test2"))),
          s(:if_flag, "my_flag",
            s(:test,
              s(:object, "test1"))),
          s(:if_flag, "my_flag",
            s(:test,
              s(:object, "test2")))))
  end

  it "condition block methods can be inhibited with :or" do
    # This is a legacy feature provided by OrigenTesters
    if_enable "my_flag" do
      test :test1
    end
    if_enable "my_flag", or: false do
      test :test2
    end
    if_enable "my_flag", or: true do
      test :test3
    end

    atp.ast(optimization: :full, add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_enabled, "my_flag",
          s(:test,
            s(:object, "test1")),
          s(:test,
            s(:object, "test2"))),
        s(:test,
          s(:object, "test3")))
  end
end
