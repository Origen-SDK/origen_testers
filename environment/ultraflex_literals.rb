OrigenTesters::UltraFLEX.new(literal_flags: true, literal_enables: true)

# Optional - provide 
tester.literal_flag_options = {
  type_first: true,
  fail_name: 'f',
  pass_name: 'p',
  using_f_p_instead_FAILED_PASSED: true,
  flag_included_flow_name: true
}
