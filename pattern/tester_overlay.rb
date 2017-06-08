Pattern.create(name: "test_overlay") do
  tester.overlay_style = :digsrc
  cc 'should get a repeat count added to this vector for digsrc start minimum distance'
  tester.cycle
  
  dut.pin(:tclk).drive(1)
  dut.pin(:tdi).drive(1)
  dut.pin(:tdo).assert(1)
  dut.pin(:tms).drive(1)
  
  cc 'should get a repeat 5 vector'
  tester.cycle repeat: 5
  
  cc 'should get a send microcode and 1 cycle with D'
  tester.cycle
  tester.overlay "dummy_str", pins: dut.pin(:tdi_a)
  cc 'should get a cycle with D and no send'
  tester.cycle
  tester.overlay "dummy_str", pins: dut.pin(:tdi), change_data: false
  cc 'regular cycle with no D or send'
  tester.cycle
  
  cc 'cycle with 001 on pa'
  dut.pin(:pa).drive!(1)
  cc 'send microcode followed by DDD on pa'
  dut.pin(:pa).drive!(0)
  tester.overlay "dummy_str", pins: dut.pin(:pa)
  cc 'cycle with 001 on pa'
  dut.pin(:pa).drive!(1)
  cc 'send microcode, DDD on pa with repeat 5 (will send 5 sets of data)'
  dut.pin(:pa).drive(0)
  tester.cycle repeat: 5
  tester.overlay "dummy_str", pins: dut.pin(:pa)
  cc 'cycle with 001 on pa'
  dut.pin(:pa).drive!(1)
  
  # Now kick the tires of subroutine based overlay
  # No vectors with the comment "// overlay deletes" should be kept
  tester.overlay_style = :subroutine
  dut.pin(:pa).drive(7)
  tester.cycle inline_comment: 'overlay keeps'
  tester.cycle inline_comment: 'overlay deletes'
  tester.overlay "subr_test", pins: dut.pin(:tdi)
end