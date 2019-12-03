# Flow to exercise the Flow Control API
#
# Some of the other flows also cover the flow control API and those tests are used
# to guarantee that the test ID references work when sub-flows are involved.
# This flow provides a full checkout of all flow control methods.
Flow.create interface: 'OrigenTesters::Test::Interface', flow_name: "Flow Control Testing" do
  flow.flow_description = 'Flow to exercise the Flow Control API' if tester.v93k?

  self.resources_filename = 'flow_control'

  log "Test that if_failed works"
  func :read1, id: :t1, bin: 10, number: 50000
  func :erase1, if_failed: :t1, bin: 12, number: 50010

  log "Test the block form of if_failed"
  func :read2, id: :t2, bin: 10, number: 50020
  if_failed :t2 do
    func :erase2, number: 50030
    func :erase2, number: 50040
  end

  log "Test that if_passed works"
  func :read1, id: :t3, bin: 10, number: 50050
  func :pgm1, if_passed: :t3, number: 50060

  log "Test the block form of if_passed"
  func :read2, id: :t4, bin: 10, number: 50070
  if_passed :t4 do
    func :pgm1, number: 50080
    func :pgm1, number: 50090
  end

  log "Test that if_ran works"
  func :pgm, id: :t5, bin: 10, number: 50100
  func :read0, if_ran: :t5, number: 50110

  log "Test the block form of if_ran"
  func :pgm, id: :t6, bin: 10, number: 50120
  if_ran :t6 do
    func :read0, number: 50130
    func :read0, number: 50140
  end

  log "Test that unless_ran works"
  func :pgm, id: :t7, bin: 10, number: 50150
  func :read0, unless_ran: :t7, number: 50160

  log "Test the block form of unless_ran"
  func :pgm, id: :t8, bin: 10, number: 50170
  unless_ran :t8 do
    func :read0, number: 50180
    func :read0, number: 50190
  end

  log "Test that if_job works"
  func :cold_test, if_job: :fc, number: 50200

  log "Test the block form of if_job"
  if_job [:prb1, :prb2] do
    func :probe_only_test1, number: 50210
    func :probe_only_test2, number: 50220
  end

  log "Test that the block form of if_job can be overridden, prb9 should be removed"
  if_job [:prb1, :prb2, :prb9] do
    func :probe_only_test1, number: 50230
  end

  log "Test that unless_job works"
  func :warmish_test, unless_job: :fc, number: 50240

  log "Test the block form of unless_job"
  unless_job [:prb1, :prb2] do
    func :ft_only_test1, number: 50250
    func :ft_only_test2, number: 50260
  end

  log "Test that if_enable works"
  func :extra_test, if_enable: :extras, number: 50270

  log "Test the block form of if_enable"
  if_enable :cz do
    func :cz_test1, number: 50280
    func :cz_test2, number: 50290
  end

  log "Test that unless_enable works"
  func :long_test, unless_enable: :quick, number: 50300

  log "Test the block form of unless_enable"
  unless_enable :quick do
    func :long_test1, number: 50310
    func :long_test2, number: 50320
  end

  log "Test that if_any_failed works"
  func :test1, id: :ifa1, number: 50330
  func :test2, id: :ifa2, number: 50340
  func :test3, if_any_failed: [:ifa1, :ifa2], number: 50350

  log "Test the block form of if_any_failed"
  func :test1, id: :oof_passcode1, number: 50360
  func :test2, id: :oof_passcode2, number: 50370
  if_any_failed :oof_passcode1, :oof_passcode2 do
    func :test3, number: 50380
    func :test4, number: 50390
  end

  log "Test that if_all_failed works"
  func :test1, id: :ifall1, number: 50400
  func :test2, id: :ifall2, number: 50410
  func :test3, if_all_failed: [:ifall1, :ifall2], number: 50420

  log "Test the block form of if_all_failed"
  func :test1, id: :ifallb1, number: 50430
  func :test2, id: :ifallb2, number: 50440
  if_all_failed [:ifallb1, :ifallb2] do
    func :test3, number: 50450
    func :test4, number: 50460
  end

  log "Test that if_any_passed works"
  func :test1, id: :ifap1, number: 50470
  func :test2, id: :ifap2, number: 50480
  func :test3, if_any_passed: [:ifap1, :ifap2], number: 50490

  log "Test the block form of if_any_passed"
  func :test1, id: :ifapb1, number: 50500
  func :test2, id: :ifapb2, number: 50510
  if_any_passed :ifapb1, :ifapb2 do
    func :test3, number: 50520
    func :test4, number: 50530
  end

  log "Test that if_all_passed works"
  func :test1, id: :ifallp1, number: 50540
  func :test2, id: :ifallp2, number: 50550
  func :test3, if_all_passed: [:ifallp1, :ifallp2], number: 50560

  log "Test the block form of if_all_passed"
  func :test1, id: :ifallpb1, number: 50570
  func :test2, id: :ifallpb2, number: 50580
  if_all_passed :ifallpb1, :ifallpb2 do
    func :test3, number: 50590
    func :test4, number: 50600
  end

  log "Test that group-level dependencies work"
  group "grp1", id: :grp1 do
    func :grp1_test1, bin: 5, number: 50610
    func :grp1_test2, bin: 5, number: 50620
    func :grp1_test3, bin: 5, number: 50630
  end

  group "grp2", if_failed: :grp1 do
    func :grp2_test1, bin: 5, number: 50640
    func :grp2_test2, bin: 5, number: 50650
    func :grp2_test3, bin: 5, number: 50660
  end

  log "Another group-level dependencies test based on a real life use case"
  func :gt1, bin: 90, number: 50670
  group "gt_grp1", id: :gt_grp1 do
    func :gt_grp1_test1, bin: 90, id: :gt_grp1, number: 50680
    func :gt_grp1_test2, bin: 90, id: :gt_grp1, number: 50690
  end
  func :gt2, bin: 90, if_failed: :gt_grp1, number: 50700
  group "gt_grp2", id: :gt_grp2, if_failed: :gt_grp1 do
    # The if_failed and IDs here are redundant, but it should still generate
    # valid output if an application were to do this
    func :gt_grp2_test1, bin: 90, id: :gt_grp2, if_failed: :gt_grp1, number: 50710
    func :gt_grp2_test2, bin: 90, id: :gt_grp2, if_failed: :gt_grp1, number: 50720
  end
  func :gt3, bin: 90, if_failed: :gt_grp2, number: 50730

  log "Test that nested groups work"
  group "level1" , comment: "Level 1 Group" do
    func :lev1_test1, bin: 5, number: 50740
    func :lev1_test2, bin: 5, number: 50750
    func :lev1_test3, id: :l1t3, bin: 10, number: 50760
    func :lev1_test4, if_failed: :l1t3, bin: 12, number: 50770
    func :lev1_test5, id: :l1t5, bin: 12, number: 50780
    group "level2" , bypass: true do
      func :lev2_test1, bin: 5, number: 50790
      func :lev2_test2, bin: 5, number: 50800
      func :lev2_test3, id: :l2t3, bin: 10, number: 50810
      func :lev2_test4, if_failed: :l2t3, bin: 12, number: 50820
      # Test dependency on a test from another group
      func :lev2_test5, if_failed: :l1t5, bin: 12, number: 50830
    end
  end

  log "Test nested conditions on a group"
  func :nt1, bin: 10, id: :nt1, number: 50840
  if_failed :nt1 do
    func :nt2, bin: 11, id: :nt2, number: 50850
    group "ntg1", id: :ntg1, if_passed: :nt2 do
      func :nt3, bin: 12, number: 50860
    end
    group "ntg2", id: :ntg2, if_failed: :nt2 do
      func :nt4, bin: 13, number: 50870
    end
  end

  log "Embedded conditional tests 1"
  func :test1, id: :ect1_1, number: 50880
  if_failed :ect1_1 do
    func :test2, number: 50890
    func :test3, id: :ect1_3, number: 50900
    if_failed :ect1_3 do
      func :test4, number: 50910
    end
  end

  log "Embedded conditional tests 2"
  func :test1, id: :ect2_1, number: 50920
  func :test2, id: :ect2_2, number: 50930
  if_failed :ect2_1 do
    func :test3, if_failed: :ect2_2, number: 50940
    func :test4, if_enable: "en1", number: 50950
    if_enable "en2" do
      func :test5, number: 50960
      func :test6, number: 50970
    end
    func :test7, number: 50980
  end
  func :test8, number: 51000

  log "Nested enable word test 1"
  if_enable "word1" do
    func :test1, number: 51010
    if_enable "word2" do
      func :test2, number: 51020
    end
  end

  log "Nested enable word test 2"
  if_enable "word1" do
    func :test1, number: 51030
    unless_enable "word2" do
      func :test2, number: 51040
    end
  end

  log "Nested enable word test 3"
  if_enable ["word1", "word2"] do
    func :test1, number: 51050
    if_enable "word3" do
      func :test2, number: 51060
    end
  end

  log "Conditional enable test"
  enable :nvm_minimum_ft, if_enable: "nvm_minimum_room", if_job: :fr
  enable :nvm_minimum_ft, if_enable: "nvm_minimum_cold", if_job: :fc
  disable :nvm_minimum_ft, if_enable: "nvm_minimum_hot", if_job: :fh

  log "Test enable words that wrap a lot of tests"
  if_enable :word1 do
    5.times do |i|
      func :test1, number: 51100 + (i * 10)
    end
    if_enable :word2 do
      4.times do |i|
        func :test1, number: 51200 + (i * 10)
      end
      func :test1, enable: :word3, number: 51300
    end
  end

  if tester.j750?
    log "This should generate an AND flag"
    func :test1, id: :at1, number: 51310
    func :test2, id: :at2, number: 51320
    if_failed :at1 do
      func :test3, if_failed: :at2, number: 51330
      # This should re-use the AND flag, rather than create a duplicate
      func :test4, if_failed: :at2, number: 51340
    end 
    log "This should NOT generate an AND flag"
    # Creating an AND flag here is logically correct, but creates un-necessary flow lines. Since
    # the test at11 is already gated by the at21 condition, it does not need to be applied to any
    # tests that are dependent on at11.
    func :test1, id: :at11, number: 51350
    if_failed :at11 do
      func :test2, id: :at21, number: 51360
      func :test3, if_failed: :at21, number: 51370
      func :test4, if_failed: :at21, number: 51380
    end 
  end

  log "Manual flag setting"
  test :test1, on_fail: { set_flag: :my_flag }, continue: true, number: 51390
  test :test2, if_flag: :my_flag, number: 51400
  unless_flag :my_flag do
    test :test3, number: 51410
  end
  
  log "Mixed-case manual flags"
  test :test1, on_fail: { set_flag: :$My_Mixed_Flag }, continue: true, number: 51420
  test :test2, if_flag: "$My_Mixed_Flag", number: 51430
  unless_flag "$My_Mixed_Flag" do
    test :test3, number: 51440
  end
  
  log "Mixed-case enables"
  test :extra_test, if_enable: :$MCEn_extras, number: 51450
  unless_enable "$MCEn_test" do
    test :test1, number: 51460
    test :test2, number: 51470
  end

  if tester.v93k?
    log "This should retain the set-run-flag in the else conditional"
    func :test22, id: :at22, number: 51480
    
    if_failed :at22 do
      func :test22a, number: 51490
      func :test22b, number: 51500
    end 
    
    func :test22c, number: 51510
    func :test22d, number: 51520
  
    if_failed :at22 do
      func :test22e, number: 51530
      func :test22f, number: 51540
    end 
  end

  if tester.v93k?
    log "This should optimize away then/else branches that are empty"
    func :test36, continue: true, number: 51550
    func :test36b, bin: 12, continue:true, number: 51560

    log "Tests of render"

    render 'multi_bin;', if_flag: :my_flag

    func :test36, on_fail: { render: 'multi_bin;' }, if_flag: :my_flag, number: 51570
  end

  log 'An optimization test case, this should not generate a flag on V93K'
  func :test1, id: :t1a, number: 51580

  if_passed :t1a do
    func :test2, number: 51590
  end

  if_failed :t1a do
    func :test3, number: 51600
    bin 10
  end

  log 'The reverse optimization test case, this should not generate a flag on V93K'
  func :test1, id: :t1b, number: 51610

  if_failed :t1b do
    func :test3, number: 51620
    bin 10
  end

  if_passed :t1b do
    func :test2, number: 51630
  end

  if tester.v93k?
    log 'Nested optimization test case'
    func :outer_test, id: :ot, number: 51640
    if_failed :ot do
      unless_flag :flag1 do
        func :inner_test1, id: :it1, number: 51650
        render 'multi_bin;', if_failed: :it1
      end
    end

    log 'Nested flag optimization test case'
    if_flag :flag1 do
      func :test4, id: :nf_t4, number: 51660
      if_failed :nf_t4 do
        render 'multi_bin;', if_flag: :flag1
      end
    end

    log 'Same test case with volatile flag'
    volatile :$Alarm
    if_flag :$Alarm do
      func :test10, id: :nf_t5, number: 51670
      if_failed :nf_t5 do
        render 'multi_bin;', if_flag: :$Alarm
      end
    end

    log 'The setting of flags used in later OR conditions should be preserved'
    func :test2, id: :of1, number: 51680
    func :test3, if_failed: :of1, number: 51690
    func :test2, id: :of2, number: 51700
    func :test3, if_failed: :of2, number: 51710
    func :test4, number: 51720
    func :test4, if_any_failed: [:of1, :of2], number: 51730

    log 'The setting of flags used in later AND conditions should be preserved'
    func :test2, id: :af1, number: 51740
    func :test3, if_failed: :af1, number: 51750
    func :test2, id: :af2, number: 51760
    func :test3, if_failed: :af2, number: 51770
    func :test4, number: 51780
    func :test4, if_all_failed: [:af1, :af2], number: 51790
    
    log 'Adjacent tests that set a flag and then use it in an OR condition should be valid'
    func :test2, id: :of11, number: 51800
    func :test2, id: :of12, number: 51810
    func :test4, if_any_failed: [:of11, :of12], number: 51820

    log 'Adjacent tests that set a flag and then use it in an AND condition should be valid'
    func :test2, id: :af11, number: 51830
    func :test2, id: :af12, number: 51840
    func :test4, if_all_failed: [:af11, :af12], number: 51850

    log 'Adjacent if combiner test case 1'
    func :test1, if_enable: :my_enable_word, number: 51860
    func :test2, unless_enable: :my_enable_word, number: 51870
    func :test1, if_flag: :my_flag, number: 51880
    func :test2, unless_flag: :my_flag, number: 51890

    log 'Adjacent if combiner test case 2'
    func :test2, unless_enable: :my_enable_word, number: 51900
    func :test1, if_enable: :my_enable_word, number: 51910
    func :test2, unless_flag: :my_flag, number: 51920
    func :test1, if_flag: :my_flag, number: 51930

    log 'Volatile if combiner test case'
    func :test1, if_flag: :$Alarm, number: 51940
    func :test2, unless_flag: :$Alarm, number: 51950

    # The is auto-generated comment from hashtag
    func_with_comment :test1, number: 51952

    cc 'The is auto-generated comment from cc'
    func_with_comment :test1, number: 51954

    log 'Use bin_attrs to set not_over_on'
    func :test1n, number: 51956, bin: 12, bin_attrs: { not_over_on: true }

  end

  log 'Test the block form of expressing if passed/failed dependents'
  func :test1, on_pass: ->{
    func :test2, number: 51970
  }, on_fail: ->{
    func :test3, number: 51980
    bin 10
  }, number: 51960

  log 'Test the else block on a flag condition'
  if_enabled "bitmap", then: ->{
    test :test2, number: 51990
  }, else: ->{
    test :test3, number: 52000
  }
  if_flag :some_flag, then: ->{
    test :test2, number: 52010
  }, else: ->{
    test :test3, number: 52020
  }

  log 'Test of a real life case which was found to have problems'
  unless_enable "eword1" do
    unless_enable "eword2" do
      import 'components/small', number: 53000
    end
    if_enable "eword2" do
      import 'components/small', number: 54000
    end
  end

  if tester.v93k?
    log 'Test some expressions'
    set '$LT_VARIABLE', "FALSE"

    whenever lt(3, 5) do
      set '$LT_VARIABLE', "TRUE"
      func :test_3lt5, number: 55000
    end

    whenever eq('$LT_VARIABLE', "TRUE") do
      bin 12
    end

    whenever_any gt('$FIVE', '$FOUR'), ne(5, 4) do
      func :test_5gt4_or_4gt5, number: 55002
    end

    whenever_all ge('$FIVE_PNT_TWO', 5.1), lt(4, 3) do
      func :test_5gt4_and_4gt3, number: 55004
    end

  end

  if tester.igxl?
    log "Test that if_any_site_failed works"
    func :read1, id: :ta1, bin: 10, number: 60000
    func :erase1, if_any_site_failed: :ta1, bin: 12, number: 60010

    log "Test the block form of if_any_site_failed"
    func :read2, id: :ta2, bin: 10, number: 60020
    if_any_site_failed :ta2 do
      func :erase2, number: 60030
      func :erase2, number: 60040
    end

    log "Test that if_all_sites_failed works"
    func :read1, id: :ta3, bin: 10, number: 60000
    func :erase1, if_all_sites_failed: :ta3, bin: 12, number: 60010

    log "Test that if_any_sites_passed works"
    func :read1, id: :ta4, bin: 10, number: 60000
    func :erase1, if_any_sites_passed: :ta4, bin: 12, number: 60010

    log "Test that if_all_sites_passed works"
    func :read1, id: :ta5, bin: 10, number: 60000
    func :erase1, if_all_sites_passed: :ta5, bin: 12, number: 60010
  end
end
