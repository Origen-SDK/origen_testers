require 'spec_helper'

# These are integration tests of all flow AST processors based
# on some real life examples
describe 'general AST optimization test cases' do

  include OrigenTesters::ATP::FlowAPI

  before :each do
    OrigenTesters::ATP::Validator.testing = true
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  def ast(options = {})
    options = {
      optimization: :smt,
    }.merge(options)
    atp.ast(options)
  end

  it "test 1" do
    log "Another group-level dependencies test based on a real life use case"
    test :gt1, bin: 90
    group :gt_grp1, id: :gt_grp1 do
      test :gt_grp1_test1, bin: 90
      test :gt_grp1_test2, bin: 90
    end
    test :gt2, bin: 90, if_failed: :gt_grp1
    group :gt_grp2, id: :gt_grp2, if_failed: :gt_grp1 do
      test :gt_grp2_test1, bin: 90
      test :gt_grp2_test2, bin: 90
    end
    test :gt3, if_failed: :gt_grp2

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:log, "Another group-level dependencies test based on a real life use case"),
        s(:test,
          s(:object, "gt1"),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 90))),
          s(:id, "t1")),
        s(:group,
          s(:name, "gt_grp1"),
          s(:id, "gt_grp1"),
          s(:test,
            s(:object, "gt_grp1_test1"),
            s(:id, "t2")),
          s(:test,
            s(:object, "gt_grp1_test2"),
            s(:id, "t3")),
          s(:dependent_types, {"failed"=>true}),
          s(:on_fail,
            s(:set_flag, "gt_grp1_FAILED", "auto_generated"))),
        s(:if_flag, "gt_grp1_FAILED",
          s(:test,
            s(:object, "gt2"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 90))),
            s(:id, "t4")),
          s(:group,
            s(:name, "gt_grp2"),
            s(:id, "gt_grp2"),
            s(:test,
              s(:object, "gt_grp2_test1"),
              s(:id, "t5")),
            s(:test,
              s(:object, "gt_grp2_test2"),
              s(:id, "t6")),
            s(:dependent_types, {"failed"=>true}),
            s(:on_fail,
              s(:set_flag, "gt_grp2_FAILED", "auto_generated")))),
        s(:if_flag, "gt_grp2_FAILED",
          s(:test,
            s(:object, "gt3"),
            s(:id, "t7"))))
  end

  it "test 2" do
    log "Test that nested groups work"
    group "level1" do
      test :lev1_test1, bin: 5
      test :lev1_test2, bin: 5
      test :lev1_test3, bin: 10, id: :l1t3
      test :lev1_test4, bin: 12, if_failed: :l1t3
      test :lev1_test5, bin: 12, id: :l1t5
      group "level2" do
        test :lev2_test1, bin: 5
        test :lev2_test2, bin: 5
        test :lev2_test3, bin: 10, id: :l2t3
        test :lev2_test4, bin: 12, if_failed: :l2t3
        test :lev2_test5, bin: 12, if_failed: :l1t5
      end
    end

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:log, "Test that nested groups work"),
        s(:group,
          s(:name, "level1"),
          s(:test,
            s(:object, "lev1_test1"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 5))),
            s(:id, "t1")),
          s(:test,
            s(:object, "lev1_test2"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 5))),
            s(:id, "t2")),
          s(:test,
            s(:object, "lev1_test3"),
            s(:id, "l1t3"),
            s(:on_fail,
              s(:test,
                s(:object, "lev1_test4"),
                s(:on_fail,
                  s(:set_result, "fail",
                    s(:bin, 12))),
                s(:id, "t3"))),
            s(:dependent_types, {"failed"=>true})),
          s(:test,
            s(:object, "lev1_test5"),
            s(:id, "l1t5"),
            s(:on_fail,
              s(:set_flag, "l1t5_FAILED", "auto_generated")),
            s(:dependent_types, {"failed"=>true})),
          s(:group,
            s(:name, "level2"),
            s(:test,
              s(:object, "lev2_test1"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 5))),
              s(:id, "t4")),
            s(:test,
              s(:object, "lev2_test2"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 5))),
              s(:id, "t5")),
            s(:test,
              s(:object, "lev2_test3"),
              s(:id, "l2t3"),
              s(:on_fail,
                s(:test,
                  s(:object, "lev2_test4"),
                  s(:on_fail,
                    s(:set_result, "fail",
                      s(:bin, 12))),
                  s(:id, "t6"))),
              s(:dependent_types, {"failed"=>true})),
            s(:if_flag, "l1t5_FAILED",
              s(:test,
                s(:object, "lev2_test5"),
                s(:on_fail,
                  s(:set_result, "fail",
                    s(:bin, 12))),
                s(:id, "t7"))),
            s(:id, "t8")),
          s(:id, "t9")))    
  end

  it "test 3" do
    test :t1, id: :check_drb_completed
    test :nvm_pass_rd_prb1_temp_old, name: :nvm_pass_rd_prb1_temp_old, number: 204016080, id: :check_prb1_new,
                                     bin: 204, softbin: 204, if_failed: :check_drb_completed
    if_failed :check_drb_completed do
      test :nvm_pass_rd_prb1_temp, name: :nvm_pass_rd_prb1_temp, number: 204016100,
                                       bin: 204, softbin: 204, if_failed: :check_prb1_new
    end
    if_failed :check_drb_completed do
      if_enabled :data_collection do
        test :nvm_dist_vcg, name: "PostDRB", number: 16120, continue: true, if_enabled: :data_collection
      end
    end
    if_enabled :data_collection_all do
      if_failed :check_drb_completed do
        test :nvm_dist_vcg_f, name: "PostDRBFW", number: 16290, continue: true
      end
    end
    if_enabled :data_collection_all do
      if_failed :check_drb_completed do
        test :nvm_dist_vcg_t, name: "PostDRBTIFR", number: 16460, continue: true
      end
    end
    if_enabled :data_collection_all do
      if_failed :check_drb_completed do
        test :nvm_dist_vcg_u, name: "PostDRBUIFR", number: 16630, continue: true
      end
    end

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "t1"),
          s(:id, "check_drb_completed"),
          s(:dependent_types, {"failed"=>true}),
          s(:on_fail,
            s(:test,
              s(:object, "nvm_pass_rd_prb1_temp_old"),
              s(:name, "nvm_pass_rd_prb1_temp_old"),
              s(:number, 204016080),
              s(:id, "check_prb1_new"),
              s(:on_fail,
                s(:test,
                  s(:object, "nvm_pass_rd_prb1_temp"),
                  s(:name, "nvm_pass_rd_prb1_temp"),
                  s(:number, 204016100),
                  s(:on_fail,
                    s(:set_result, "fail",
                      s(:bin, 204),
                      s(:softbin, 204))),
                  s(:id, "t1"))),
              s(:dependent_types, {"failed"=>true})),
            s(:if_enabled, "data_collection",
              s(:test,
                s(:object, "nvm_dist_vcg"),
                s(:name, "PostDRB"),
                s(:number, 16120),
                s(:id, "t2"))),
            s(:if_enabled, "data_collection_all",
              s(:test,
                s(:object, "nvm_dist_vcg_f"),
                s(:name, "PostDRBFW"),
                s(:number, 16290),
                s(:id, "t3")),
              s(:test,
                s(:object, "nvm_dist_vcg_t"),
                s(:name, "PostDRBTIFR"),
                s(:number, 16460),
                s(:id, "t4")),
              s(:test,
                s(:object, "nvm_dist_vcg_u"),
                s(:name, "PostDRBUIFR"),
                s(:number, 16630),
                s(:id, "t5"))))))
  end

  it "embedded common rules test" do
    if_job :j1 do
      test :test1, if_enabled: :bitmap
    end
    if_job :j2 do
      test :test2, if_enabled: :bitmap
    end

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_enabled, "bitmap",
          s(:if_job, "j1",
            s(:test,
              s(:object, "test1"),
              s(:id, "t1"))),
          s(:if_job, "j2",
            s(:test,
              s(:object, "test2"),
              s(:id, "t2")))))
  end

  it 'test case from origen_testers' do
    log "Test nested conditions on a group"
    test :test1, name: :nt1, number: 0, id: :nt1, bin: 10
    test :test2, name: :nt2, number: 0, id: :nt2, bin: 11, if_failed: :nt1
    if_passed :nt2 do
      group "ntg1", id: :ntg1 do
        test :test3, name: :nt3, number: 0, bin: 12, if_failed: :nt1
      end
    end
    group "ntg2", id: :ntg2, if_failed: :nt2 do
      test :test4, name: :nt4, number: 0, bin: 13, if_failed: :nt1
    end

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:log, "Test nested conditions on a group"),
        s(:test,
          s(:object, "test1"),
          s(:name, "nt1"),
          s(:number, 0),
          s(:id, "nt1"),
          s(:on_fail,
            s(:test,
              s(:object, "test2"),
              s(:name, "nt2"),
              s(:number, 0),
              s(:id, "nt2"),
              s(:on_fail,
                s(:group,
                  s(:name, "ntg2"),
                  s(:id, "ntg2"),
                  s(:test,
                    s(:object, "test4"),
                    s(:name, "nt4"),
                    s(:number, 0),
                    s(:on_fail,
                      s(:set_result, "fail",
                        s(:bin, 13))),
                    s(:id, "t2")))),
              s(:dependent_types, {"passed"=>true, "failed"=>true}),
              s(:on_pass,
                s(:group,
                  s(:name, "ntg1"),
                  s(:id, "ntg1"),
                  s(:test,
                    s(:object, "test3"),
                    s(:name, "nt3"),
                    s(:number, 0),
                    s(:on_fail,
                      s(:set_result, "fail",
                        s(:bin, 12))),
                    s(:id, "t1")))))),
          s(:dependent_types, {"failed"=>true})))
  end

  it "a test case where test3 was lost" do
    test :test1, id: :ifallb1
    test :test2, id: :ifallb2
    if_all_failed [:ifallb1, :ifallb2] do
      test :test3
      test :test4
    end

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "ifallb1"),
          s(:dependent_types, {"failed"=>true}),
          s(:on_fail,
            s(:set_flag, "ifallb1_FAILED", "auto_generated"))),
        s(:test,
          s(:object, "test2"),
          s(:id, "ifallb2"),
          s(:dependent_types, {"failed"=>true}),
          s(:on_fail,
            s(:if_flag, "ifallb1_FAILED",
              s(:test,
                s(:object, "test3"),
                s(:id, "t1")),
              s(:test,
                s(:object, "test4"),
                s(:id, "t2"))))))
  end

  it "a test case that ended up with an additional render" do
    render 'multi_bin;', if_flag: :my_flag
    test :test1, on_fail: { render: 'multi_bin;' }, if_flag: :my_flag

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_flag, "my_flag",
          s(:render, "multi_bin;"),
          s(:test,
            s(:object, "test1"),
            s(:on_fail,
              s(:render, "multi_bin;")),
            s(:id, "t1"))))
  end

  it "a test case that dropped a bin out" do
    test :test1, id: :t1a

    if_passed :t1a do
      test :test2
    end

    if_failed :t1a do
      test :test3
      bin 10
    end

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1a"),
          s(:dependent_types, {"passed"=>true, "failed"=>true}),
          s(:on_pass,
            s(:test,
              s(:object, "test2"),
              s(:id, "t1"))),
          s(:on_fail,
            s(:test,
              s(:object, "test3"),
              s(:id, "t2")),
            s(:set_result, "fail",
              s(:bin, 10)))))    
  end

  it "a test case which got it really confused" do
    unless_enable "eword1" do
      unless_enable "eword2" do
        test :test1, if_enable: :small_flow
        test :test2, if_enable: :small_flow
        test :test1
        test :test1
        test :test1
        test :test1
        test :test1, if_enable: :small_flow
        test :test2, if_enable: :small_flow       
      end
      if_enable "eword2" do
        test :test1, if_enable: :small_flow
        test :test2, if_enable: :small_flow
        test :test1
        test :test1
        test :test1
        test :test1
        test :test1, if_enable: :small_flow
        test :test2, if_enable: :small_flow       
      end
    end

    ast(add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:unless_enabled, "eword1",
          s(:unless_enabled, "eword2",
            s(:if_enabled, "small_flow",
              s(:test,
                s(:object, "test1")),
              s(:test,
                s(:object, "test2"))),
            s(:test,
              s(:object, "test1")),
            s(:test,
              s(:object, "test1")),
            s(:test,
              s(:object, "test1")),
            s(:test,
              s(:object, "test1")),
            s(:if_enabled, "small_flow",
              s(:test,
                s(:object, "test1")),
              s(:test,
                s(:object, "test2")))),
          s(:if_enabled, "eword2",
            s(:if_enabled, "small_flow",
              s(:test,
                s(:object, "test1")),
              s(:test,
                s(:object, "test2"))),
            s(:test,
              s(:object, "test1")),
            s(:test,
              s(:object, "test1")),
            s(:test,
              s(:object, "test1")),
            s(:test,
              s(:object, "test1")),
            s(:if_enabled, "small_flow",
              s(:test,
                s(:object, "test1")),
              s(:test,
                s(:object, "test2"))))))
  end

  it "A test case where the nested if_failed flag wasn't rendering" do
    test :test1, id: :t1, on_fail: ->{
      if_flag "TestFlag" do
        bin 1
      end
      unless_flag "TestFlag" do
        test :test2, id: :t2, on_fail: ->{
          if_flag "TestFlag" do
            bin 1
          end
        }
        unless_flag "TestFlag" do
          bin 2, if_failed: :t2
        end
      end
    }

    expect { atp.ast }.to raise_error(SystemExit).
      and output(/if_flag and unless_flag conditions cannot be nested and refer to the same flag/).to_stdout
  end

  it "Same test as above with volatile flag" do
    volatile "TestFlag"
    test :test1, id: :t1, on_fail: ->{
      if_flag "TestFlag" do
        bin 1
      end
      unless_flag "TestFlag" do
        test :test2, id: :t2, on_fail: ->{
          if_flag "TestFlag" do
            bin 1
          end
        }
        unless_flag "TestFlag" do
          bin 2, if_failed: :t2
        end
      end
    }

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:volatile,
          s(:flag, "TestFlag")),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1"),
          s(:on_fail,
            s(:if_flag, "TestFlag",
              s(:set_result, "fail",
                s(:bin, 1)),
              s(:else,
                s(:test,
                  s(:object, "test2"),
                  s(:id, "t2"),
                  s(:on_fail,
                    s(:if_flag, "TestFlag",
                      s(:set_result, "fail",
                        s(:bin, 1)),
                      s(:else,
                        s(:set_result, "fail",
                          s(:bin, 2))))),
          s(:dependent_types, {"failed"=>true})))))))
  end

  it "A test case where the if_passed/if_failed wasn't rendering properly" do
    test :test1, id: :t1
    if_failed :t1, then: ->{
      bin 2
    }, else: ->{
      if_flag "TestFlag", then: ->{ bin 1 }, else: ->{
        test :test2, id: :t2
        bin 3, if_failed: :t2
      }
    }
    
    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1"),
          s(:dependent_types, {"failed"=>true}),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 2)),
            s(:else,
              s(:if_flag, "TestFlag",
                s(:set_result, "fail",
                  s(:bin, 1)),
                s(:else,
                  s(:test,
                    s(:object, "test2"),
                    s(:id, "t2"),
                    s(:dependent_types, {"failed"=>true}),
                    s(:on_fail,
                      s(:set_result, "fail",
                        s(:bin, 3))))))))))
  end
end
