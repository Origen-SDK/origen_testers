# An instance of the interface is
# passed in here, iterators and other
# argument passing will be supported
# similar to Pattern.create.
Flow.create interface: 'OrigenTesters::Test::Interface' do

  # Instantiate tests via the
  # interface
#  func 'program_ckbd', :tname => 'PGM_CKBD', :tnum => 1000, :bin => 100, :soft_bin => 1100

#  para 'charge_pump', :high_voltage => true, :lo_limit => 5, :hi_limit => 6

  if tester.v93k? && tester.create_limits_file
    func :program_ckbd, number: 1000, bin: 100, soft_bin: 1100, number: 40000
  end
  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, lo_limit: 35, number: 40005
  meas :read_pump, tnum: 1060, bin: 119, soft_bin: 2, hi_limit: 45, number: 40010
  meas :read_pump, tnum: 1070, bin: 119, soft_bin: 2, hi_limit: 45, lo_limit: 35, number: 40020
  meas :read_pump, tnum: 1080, bin: 119, soft_bin: 2, hi_limit: 45, lo_limit: 35, number: 40030
  meas :read_pump, tnum: 1090, bin: 119, soft_bin: 2, hi_limit: 45.mV, lo_limit: 35.mV, number: 40040
  meas :read_pump, tnum: 1100, bin: 119, soft_bin: 2, hi_limit: 45.mV, lo_limit: 35.mV, continue: true, number: 40050
  meas :read_pump, tnum: 1110, bin: 119, soft_bin: 2, hi_limit: 2000, lo_limit: 0.01, continue: true, number: 40060
  unless tester.v93k? && tester.create_limits_file
    meas :read_pump, tnum: 1120, bin: 119, soft_bin: 2, hi_limit: "_some_spec", lo_limit: 0.01, continue: true, number: 40070
    meas :read_pump, tnum: 1130, bin: 119, soft_bin: 2, hi_limit: [1, 2], number: 40080
    meas :read_pump, tnum: 1140, bin: 119, soft_bin: 2, lo_limit: [1.uA, 2.uA, 3.uA], hi_limit: [4.uA,5.uA], units: "A", defer_limits: true, number: 40090
  end

  if tester.uflex?
    log "Test of ultraflex render API"
    line = flow.ultraflex.use_limit
    line.units = "Hz"
  end
end
