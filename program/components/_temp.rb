Flow.create do |options|

  meas :bgap_voltage_meas, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 45, number: options[:number] + 10
  meas :bgap_voltage_meas1, number: options[:number] + 20

end
