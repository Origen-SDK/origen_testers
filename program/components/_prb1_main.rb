Flow.create do |options|
  # Instantiate tests via the
  # interface
  func 'program_ckbd', tname: 'PGM_CKBD', tnum: 1000, bin: 100, soft_bin: 1100
  func 'margin_read1_ckbd', number: 1010

  # Control the build process based on
  # the current target
  if $dut.has_margin0_bug?
    func 'normal_read_ckbd', number: 1020
  else
    func 'margin_read0_ckbd', number: 1030
  end

  # Include a sub flow, example of
  # parameter passing
  import '../erase', pulses: 6, number: 2000

  # Render an ERB template, or raw
  # text file
  if $tester.j750?
    flow.render 'templates/j750/vt_flow', include_tifr: true
  end

  log 'Should be v1'
  func :program_ckbd, number: 3000
  log 'Should be v2'
  func :program_ckbd, duration: :dynamic, number: 3010
  log 'Should be v1'
  func :program_ckbd, number: 3020
  log 'Should be v2'
  func :program_ckbd, duration: :dynamic, number: 3030

  log 'Should be a v1 test instance group'
  func :program_ckbd, by_block: true, number: 3040
  log 'Should be a v2 test instance group'
  func :program_ckbd, by_block: true, duration: :dynamic, number: 3050
  log 'Should be a v1 test instance group'
  func :program_ckbd, by_block: true, number: 3060
  log 'Should be a v2 test instance group'
  func :program_ckbd, by_block: true, duration: :dynamic, number: 3070

  # Test job conditions
  func :p1_only_test, if_job: :p1, number: 3080
  if_job [:p1, :p2] do
    func :p1_or_p2_only_test, number: 3090
  end
  func :not_p1_test, unless_job: :p1, number: 3100
  func :not_p1_or_p2_test, unless_job: [:p1, :p2], number: 3110
  unless_job [:p1, :p2] do
    func :another_not_p1_or_p2_test, number: 3120
  end

  log 'Verify that a test with an external instance works'
  por number: 3130

  log 'Verify that a request to use the current context works'
  func :erase_all, if_job: :p1, number: 3140          # Job should be P1
  func :erase_all, context: :current, number: 3150    # Job should be P1
  unless_job :p2 do
    func :erase_all, context: :current, number: 3160  # Job should be P1
    func :erase_all, number: 3170                     # Job should be !P2
  end

  # Deliver an initial erase pulse
  func :erase_all, number: 3180

  # Deliver additional erase pulses as required until it verifies, maximum of 5 additional pulses
  number = 3200
  5.times do |x|
    # Assign a unique id attribute to each verify so that we know which one we are talking about when
    # making other tests dependent on it.
    # When Origen sees the if_failed dependency on a future test it will be smart enough to inhibit the binning
    # on this test without having to explicitly declare that.
    func :margin_read1_all1, id: "erase_vfy_#{x}", number: number
    number += 10
    # Run this test only if the given verify failed
    func :erase_all, if_failed: "erase_vfy_#{x}", number: number
    number += 10
  end

  # A final verify to set the binning
  func :margin_read1_all1, number: 4000

  log 'Test if enable'
  func :erase_all, if_enable: 'do_erase', number: 4010

  if_enable 'do_erase' do
    func :erase_all, number: 4020
  end

  log 'Test unless enable'
  func :erase_all, unless_enable: 'no_extra_erase', number: 4030

  unless_enable 'no_extra_erase' do
    func :erase_all, number: 4040
    func :erase_all, number: 4050
  end

  func :erase_all, number: 4060
  func :erase_all, number: 4070

  log 'Test if_passed'
  func :erase_all, id: 'erase_passed_1', number: 4080
  func :erase_all, id: 'erase_passed_2', number: 4090

  func :margin_read1_all1, if_passed: 'erase_passed_1', number: 4100
  if_passed 'erase_passed_2' do
    func :margin_read1_all1, number: 4110
  end

  log 'Test unless_passed'
  func :erase_all, id: 'erase_passed_3', number: 4120
  func :erase_all, id: 'erase_passed_4', number: 4130

  func :margin_read1_all1, unless_passed: 'erase_passed_3', number: 4140
  unless_passed 'erase_passed_4' do
    func :margin_read1_all1, number: 4150
  end

  log 'Test if_failed'
  func :erase_all, id: 'erase_failed_1', number: 4160
  func :erase_all, id: 'erase_failed_2', number: 4170

  func :margin_read1_all1, if_failed: 'erase_failed_1', number: 4180
  if_failed 'erase_failed_2' do
    func :margin_read1_all1, number: 4190
  end

  log 'Test unless_failed'
  func :erase_all, id: 'erase_failed_3', number: 4200
  func :erase_all, id: 'erase_failed_4', number: 4210

  func :margin_read1_all1, unless_failed: 'erase_failed_3', number: 4220
  unless_failed 'erase_failed_4' do
    func :margin_read1_all1, number: 4230
  end

  log 'Test if_ran'
  func :erase_all, id: 'erase_ran_1', number: 4240
  func :erase_all, id: 'erase_ran_2', number: 4250

  func :margin_read1_all1, if_ran: 'erase_ran_1', number: 4260
  if_ran 'erase_ran_2' do
    func :margin_read1_all1, number: 4270
  end

  log 'Test unless_ran'
  func :erase_all, id: 'erase_ran_3', number: 4280
  func :erase_all, id: 'erase_ran_4', number: 4290

  func :margin_read1_all1, unless_ran: 'erase_ran_3', number: 4300
  unless_ran 'erase_ran_4' do
    func :margin_read1_all1, number: 4310
  end

  log 'Verify that job context wraps import'
  if_job :fr do
    import '../erase', number: 5000
  end

  log 'Verify that job context wraps enable block within an import'
  if_job :fr do
    import '../additional_erase', number: 5500
    import '../additional_erase', force: true, number: 5600
  end

  log 'Verify that flow.cz works...'
  func :margin_read1_all1, pin_levels: :cz, cz_setup: 'vbplus_sweep', number: 5700

  log 'Verify that flow.cz works with enable words'
  if_enable 'usb_xcvr_cz' do
    func :xcvr_fs_vilvih, cz_setup: 'usb_fs_vil_cz', number: 5710
    func :xcvr_fs_vilvih, cz_setup: 'usb_fs_vih_cz', number: 5720
  end

  func :xcvr_fs_vilvih, cz_setup: 'usb_fs_vil_cz', if_enable: 'usb_xcvr_cz', number: 5730
  func :xcvr_fs_vilvih, cz_setup: 'usb_fs_vih_cz', if_enable: 'usb_xcvr_cz', number: 5740

  log 'Verify that MTO template works...'
  mto_memory :mto_read1_all1, number: 5750

  if tester.uflex?
    log 'import statement'
    import 'temp', number: 5800 

    log 'direct call'
    
    meas :bgap_voltage_meas, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 45, number: 5910
    meas :bgap_voltage_meas1, number: 5920
  end

  if tester.j750?
    meas :lo_voltage, tnum: 1150, bin: 95, soft_bin: 5, number: 5920
    meas :hi_voltage, pins: :hi_v, tnum: 1160, bin: 96, soft_bin: 6, number: 5930
    meas :ps_leakage, pins: :power, tnum: 1170, bin: 97, soft_bin: 6, number: 5940
  end

  log 'Speed binning example bug from video 5'
  group "200Mhz Tests", id: :g200 do
    test :test200_1, number: 5950
    test :test200_2, number: 5960
    test :test200_3, number: 5970
  end

  group "100Mhz Tests", if_failed: :g200, id: :g100 do
    test :test100_1, bin: 5, number: 5980
    test :test100_2, bin: 5, number: 5990
    test :test100_3, bin: 5, number: 6000
  end

  pass 2, if_ran: :g100

  log 'Test node optimization within an if_failed branch'
  func :some_func_test, id: :sft1, number: 6010

  if_failed :sft1 do
    bin 10, if_flag: "Alarm"
    bin 11, unless_flag: "Alarm"
    bin 12, if_enable: "AlarmEnabled"
    bin 13, unless_enable: "AlarmEnabled"
  end

  3.times do |i|
    cc "cc test #{i}"
    func "cc_test_#{i}".to_sym, number: 7000 + i
  end

  log 'Passing test flags works as expected'
  func :test_with_no_flags, bypass: false, output_on_pass: false, output_on_fail: false, value_on_pass: false, value_on_fail: false, per_pin_on_pass: false, per_pin_on_fail: false
  func :test_with_flags, bypass: true, output_on_pass: true, output_on_fail: true, value_on_pass: true, value_on_fail: true, per_pin_on_pass: true, per_pin_on_fail: true

  pass 1, description: "Good die!", softbin: 1
end
