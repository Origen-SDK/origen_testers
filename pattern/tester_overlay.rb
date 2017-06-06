Pattern.create(name: "testout") do
  dut.pin(:tclk).drive(1)
  dut.pin(:tdi).drive(1)
  dut.pin(:tdo).assert(1)
  dut.pin(:tms).drive(1)
  tester.cycle repeat: 5
  tester.cycle
  tester.overlay "dummy_str", pins: dut.pin(:tdi)
  tester.cycle
  tester.overlay "dummy_str", pins: dut.pin(:tdi), change_data: false
  tester.cycle
  
end