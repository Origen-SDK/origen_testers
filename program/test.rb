# An instance of the interface is
# passed in here, iterators and other
# argument passing will be supported
# similar to Pattern.create.
Flow.create do

  # Instantiate tests via the
  # interface
#  func 'program_ckbd', :tname => 'PGM_CKBD', :tnum => 1000, :bin => 100, :soft_bin => 1100

#  para 'charge_pump', :high_voltage => true, :lo_limit => 5, :hi_limit => 6

  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, lo_limit: 35
  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 45
  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 45, lo_limit: 35
  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 45, lo_limit: 35, units: "V"
  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 45, lo_limit: 35, scale: "k", units: "V"
  meas :read_pump, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 45, lo_limit: 35, scale: "k", units: "V", result: "None"

end
