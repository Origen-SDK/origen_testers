# Flow to exercise the Flow Control API related to using exact literal value of flag (no lowercase or cleanup) as
# controlled at tester API level
#
# Some of the other flows also cover the flow control API and those tests are used
# to guarantee that the test ID references work when sub-flows are involved.
# This flow provides a full checkout of all flow control methods.
Flow.create interface: 'OrigenTesters::Test::Interface', flow_name: "Flow Control Flag/Enable Literal Testing" do
  flow.flow_description = 'Flow to exercise the Flow Control API' if tester.v93k?

  self.resources_filename = 'flow_control'

  log "Test that if_failed works using Literal"
  func :read1, id: :Test__Flag1, bin: 10, number: 50000
  func :erase1, if_failed: :Test__Flag1, bin: 12, number: 50010

  log "Test the block form of if_failed"
  func :read2, id: :Test__Flag2, bin: 10, number: 50020
  if_failed :Test__Flag2 do
    func :erase2, number: 50030
    func :erase2, number: 50040
  end

  log "Test that if_passed works"
  func :read1, id: :Test__Flag3, bin: 10, number: 50050
  func :pgm1, if_passed: :Test__Flag3, number: 50060

  log "Test the block form of if_passed"
  func :read2, id: :Test__Flag4, bin: 10, number: 50070
  if_passed :Test__Flag4 do
    func :pgm1, number: 50080
    func :pgm1, number: 50090
  end

  log "Test that if_ran works"
  func :pgm, id: :Test__Flag5, bin: 10, number: 50100
  func :read0, if_ran: :Test__Flag5, number: 50110

  log "Test the block form of if_ran"
  func :pgm, id: :Test__Flag6, bin: 10, number: 50120
  if_ran :Test__Flag6 do
    func :read0, number: 50130
    func :read0, number: 50140
  end

  log "Test that unless_ran works"
  func :pgm, id: :Test__Flag7, bin: 10, number: 50150
  func :read0, unless_ran: :Test__Flag7, number: 50160

  log "Test the block form of unless_ran"
  func :pgm, id: :Test__Flag8, bin: 10, number: 50170
  unless_ran :Test__Flag8 do
    func :read0, number: 50180
    func :read0, number: 50190
  end

  log "Test that if_enable works"
  func :extra_test, if_enable: :Extras__123, number: 50270

  log "Test the block form of if_enable"
  if_enable :Cz__123 do
    func :cz_test1, number: 50280
    func :cz_test2, number: 50290
  end

  log "Test that unless_enable works"
  func :long_test, unless_enable: :Quick__123, number: 50300

  log "Test the block form of unless_enable"
  unless_enable :Quick__123 do
    func :long_test1, number: 50310
    func :long_test2, number: 50320
  end

  log "Test that if_any_failed works"
  func :test1, id: :iFA__1, number: 50330
  func :test2, id: :iFA__2, number: 50340
  func :test3, if_any_failed: [:iFA__1, :iFA__2], number: 50350

  log "Test the block form of if_any_failed"
  func :test1, id: :OOF__Passcode1, number: 50360
  func :test2, id: :OOF__Passcode2, number: 50370
  if_any_failed :OOF__Passcode1, :OOF__Passcode2 do
    func :test3, number: 50380
    func :test4, number: 50390
  end

  log "Test that if_all_failed works"
  func :test1, id: :iFall__1, number: 50400
  func :test2, id: :iFall__2, number: 50410
  func :test3, if_all_failed: [:iFall__1, :iFall__2], number: 50420

  log "Test the block form of if_all_failed"
  func :test1, id: :iFall__B1, number: 50430
  func :test2, id: :iFall__B2, number: 50440
  if_all_failed [:iFall__B1, :iFall__B2] do
    func :test3, number: 50450
    func :test4, number: 50460
  end

  log "Test that if_any_passed works"
  func :test1, id: :if__AP1, number: 50470
  func :test2, id: :if__AP2, number: 50480
  func :test3, if_any_passed: [:if__AP1, :if__AP2], number: 50490

  log "Test the block form of if_any_passed"
  func :test1, id: :if__APB1, number: 50500
  func :test2, id: :if__APB2, number: 50510
  if_any_passed :if__APB1, :if__APB2 do
    func :test3, number: 50520
    func :test4, number: 50530
  end

  log "Test that if_all_passed works"
  func :test1, id: :iFall__P1, number: 50540
  func :test2, id: :iFall__P2, number: 50550
  func :test3, if_all_passed: [:iFall__P1, :iFall__P2], number: 50560

  log "Test the block form of if_all_passed"
  func :test1, id: :iFall__PB1, number: 50570
  func :test2, id: :iFall__PB2, number: 50580
  if_all_passed :iFall__PB1, :iFall__PB2 do
    func :test3, number: 50590
    func :test4, number: 50600
  end

  log "Test that group-level dependencies work"
  group "grp1", id: :Group__1 do
    func :grp1_test1, bin: 5, number: 50610
    func :grp1_test2, bin: 5, number: 50620
    func :grp1_test3, bin: 5, number: 50630
  end

  group "grp2", if_failed: :Group__1 do
    func :grp2_test1, bin: 5, number: 50640
    func :grp2_test2, bin: 5, number: 50650
    func :grp2_test3, bin: 5, number: 50660
  end

  # Only J750 and Ultraflex are support external flags.  V93k are not supported
  if Origen.environment.name =~ /(ultraflex|j750)/
    log "Test that if_failed works using extern and exclude flow id"
    func :erase1, if_failed: :Test__extern_Flag1, bin: 12, number: 50670

    log "Test that if_passed works using extern and exclude flow id"
    func :erase1, if_passed: :Test__extern_Flag2, bin: 12, number: 50680
  end

end
