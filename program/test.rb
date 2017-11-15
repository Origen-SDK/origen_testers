# An instance of the interface is
# passed in here, iterators and other
# argument passing will be supported
# similar to Pattern.create.
Flow.create interface: 'OrigenTesters::Test::Interface' do

  # Instantiate tests via the
  # interface
#  func 'program_ckbd', :tname => 'PGM_CKBD', :tnum => 1000, :bin => 100, :soft_bin => 1100

#  para 'charge_pump', :high_voltage => true, :lo_limit => 5, :hi_limit => 6

  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, lo_limit: 35
  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 45
  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 45, lo_limit: 35
  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 45, lo_limit: 35
  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 45.mV, lo_limit: 35.mV
  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 45.mV, lo_limit: 35.mV, continue: true
  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 2000, lo_limit: 0.01, continue: true
  unless tester.v93k? && tester.create_limits_file
    meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: "_some_spec", lo_limit: 0.01, continue: true
    meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: [1, 2]
    meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, lo_limit: [1.uA, 2.uA, 3.uA], hi_limit: [4.uA,5.uA], units: "A", defer_limits: true
  end

  if tester.uflex?
    log "Test of ultraflex render API"
    line = flow.ultraflex.use_limit
    line.units = "Hz"
  end
end
