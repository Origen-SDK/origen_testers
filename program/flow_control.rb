# Flow to exercise the Flow Control API
#
# Some of the other flows also cover the flow control API and those tests are used
# to guarantee that the test ID references work when sub-flows are involved.
# This flow provides a full checkout of all flow control methods.
Flow.create do

  self.resources_filename = 'flow_control'

  log "Test that if_failed works"
  func :read1, id: :t1, bin: 10
  func :erase1, if_failed: :t1, bin: 12

  log "Test the block form of if_failed"
  func :read2, id: :t2, bin: 10
  if_failed :t2 do
    func :erase2
    func :erase2
  end

  log "Test that if_passed works"
  func :read1, id: :t3, bin: 10
  func :pgm1, if_passed: :t3

  log "Test the block form of if_passed"
  func :read2, id: :t4, bin: 10
  if_passed :t4 do
    func :pgm1
    func :pgm1
  end

  log "Test that if_ran works"
  func :pgm, id: :t5, bin: 10
  func :read0, if_ran: :t5

  log "Test the block form of if_ran"
  func :pgm, id: :t6, bin: 10
  if_ran :t6 do
    func :read0
    func :read0
  end

  log "Test that unless_ran works"
  func :pgm, id: :t7, bin: 10
  func :read0, unless_ran: :t7

  log "Test the block form of unless_ran"
  func :pgm, id: :t8, bin: 10
  unless_ran :t8 do
    func :read0
    func :read0
  end

  log "Test that skip works"
  skip do
    func :read0
    func :read0
  end

  log "Test that conditional skip works"
  skip if_passed: :t4 do
    func :read0
    func :read0
  end

  log "Test that if_job works"
  func :cold_test, if_job: :fc

  log "Test the block form of if_job"
  if_job [:prb1, :prb2] do
    func :probe_only_test1
    func :probe_only_test2
  end

  log "Test that unless_job works"
  func :warmish_test, unless_job: :fc

  log "Test the block form of unless_job"
  unless_job [:prb1, :prb2] do
    func :ft_only_test1
    func :ft_only_test2
  end

  log "Test that if_enable works"
  func :extra_test, if_enable: :extras

  log "Test the block form of if_enable"
  if_enable :cz do
    func :cz_test1
    func :cz_test2
  end

  log "Test that unless_enable works"
  func :long_test, unless_enable: :quick

  log "Test the block form of unless_enable"
  unless_enable :quick do
    func :long_test1
    func :long_test2
  end

  if $tester.v93k?
    log "Test that an id can be assigned to a test group"
    func :read1, id: :r1, bin: 10, by_block: true
    func :erase1, if_failed: :r1

    log "Test that group-level dependencies work"
    group "grp1", id: :grp1 do
      func :grp1_test1, bin: 5
      func :grp1_test2, bin: 5
      func :grp1_test3, bin: 5
    end

    group "grp2", if_failed: :grp1 do
      func :grp2_test1, bin: 5
      func :grp2_test2, bin: 5
      func :grp2_test3, bin: 5
    end

    log "Another group-level dependencies test based on a real life use case"
    func :gt1, bin: 90
    group "gt_grp1", id: :gt_grp1 do
      func :gt_grp1_test1, bin: 90, id: :gt_grp1
      func :gt_grp1_test2, bin: 90, id: :gt_grp1
    end
    func :gt2, bin: 90, if_failed: :gt_grp1
    group "gt_grp2", id: :gt_grp2, if_failed: :gt_grp1 do
      # The if_failed and IDs here are redundant, but it should still generate
      # valid output if an application were to do this
      func :gt_grp2_test1, bin: 90, id: :gt_grp2, if_failed: :gt_grp1
      func :gt_grp2_test2, bin: 90, id: :gt_grp2, if_failed: :gt_grp1
    end
    func :gt3, bin: 90, if_failed: :gt_grp2

    log "Test that nested groups work"
    group "level1" do
      func :lev1_test1, bin: 5
      func :lev1_test2, bin: 5
      func :lev1_test3, id: :l1t3, bin: 10
      func :lev1_test4, if_failed: :l1t3, bin: 12
      func :lev1_test5, id: :l1t5, bin: 12
      group "level2" do
        func :lev2_test1, bin: 5
        func :lev2_test2, bin: 5
        func :lev2_test3, id: :l2t3, bin: 10
        func :lev2_test4, if_failed: :l2t3, bin: 12
        # Test dependency on a test from another group
        func :lev2_test5, if_failed: :l1t5, bin: 12
      end
    end

    log "Test nested conditions on a group"
    func :nt1, bin: 10, id: :nt1
    if_failed :nt1 do
      func :nt2, bin: 11, id: :nt2
      group "ntg1", id: :ntg1, if_passed: :nt2 do
        func :nt3, bin: 12
      end
      group "ntg2", id: :ntg2, if_failed: :nt2 do
        func :nt4, bin: 13
      end
    end
  end
end
