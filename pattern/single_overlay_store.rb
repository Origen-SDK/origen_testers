Pattern.create(name: "test_single_overlay_store") do
  tester.cycle
  
  dut.pin(:tclk).drive(1)
  dut.pin(:tdi).drive(1)
  dut.pin(:tdo).assert(1)
  dut.pin(:tms).drive(1)
  
  cc 'should get a repeat 5 vector'
  tester.cycle repeat: 5
  
  cc 'should get a send microcode and 1 cycle with D'
  tester.cycle overlay: {overlay_str: 'dummy_str', pins: dut.pin(:tdi_a)}
  cc 'should get a cycle with D and no send'
  tester.cycle overlay: {overlay_str: 'dummy_str', pins: dut.pin(:tdi_a), change_data: false}
  cc 'regular cycle with no D or send'
  tester.cycle
    
  tester.store!(dut.pin(:tdo))
  tester.cycle
end