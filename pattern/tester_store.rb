Pattern.create(name: "test_store") do
  tester.capture_style = :digcap
  tester.cycle

  dut.pin(:tclk).drive(1)
  dut.pin(:tdi).drive(1)
  dut.pin(:tdo).assert(1)
  dut.pin(:tms).drive(1)
  
  cc 'should get a repeat 5 vector'
  tester.cycle repeat: 5
  tester.cycle
  tester.store(dut.pin(:tdo))
  
  tester.cycle
  tester.cycle
  
  dut.pin(:tclk).drive(0)
  tester.store!(dut.pin(:tdo))
  tester.cycle
  tester.cycle
end