# An instance of the interface is
# passed in here, iterators and other
# argument passing will be supported
# similar to Pattern.create.
Flow.create interface: 'OrigenTesters::Test::Interface' do

  self.resources_filename = 'prb1'

  # Instantiate tests via the
  # interface
  func 'program_ckbd', :tname => 'PGM_CKBD', :tnum => 1000, :bin => 100, :soft_bin => 1100
  func 'margin_read1_ckbd'

  # Control the build process based on
  # the current target
  if $dut.has_margin0_bug?
    func 'normal_read_ckbd'
  else
    func 'margin_read0_ckbd'
  end

  # Include a sub flow, example of
  # parameter passing
  import 'erase', :pulses => 6

  # Render an ERB template, or raw
  # text file
  if $tester.j750?
    flow.render 'templates/j750/vt_flow', :include_tifr => true
  end

  log 'Should be v1'
  func :program_ckbd
  log 'Should be v2'
  func :program_ckbd, :duration => :dynamic
  log 'Should be v1'
  func :program_ckbd
  log 'Should be v2'
  func :program_ckbd, :duration => :dynamic

  log 'Should be a v1 test instance group'
  func :program_ckbd, :by_block => true
  log 'Should be a v2 test instance group'
  func :program_ckbd, :by_block => true, :duration => :dynamic
  log 'Should be a v1 test instance group'
  func :program_ckbd, :by_block => true
  log 'Should be a v2 test instance group'
  func :program_ckbd, :by_block => true, :duration => :dynamic

  # Test job conditions
  func :p1_only_test, :if_job => :p1
  if_job [:p1, :p2] do
    func :p1_or_p2_only_test
  end
  func :not_p1_test, :unless_job => :p1
  func :not_p1_or_p2_test, :unless_job => [:p1, :p2]
  unless_job [:p1, :p2] do
    func :another_not_p1_or_p2_test
  end

  log 'Verify that a test with an external instance works'
  por

  log 'Verify that a request to use the current context works'
  func :erase_all, :if_job => :p1             # Job should be P1
  func :erase_all, :context => :current    # Job should be P1
  unless_job :p2 do
    func :erase_all, :context => :current  # Job should be P1
    func :erase_all                        # Job should be !P2
  end

  # Deliver an initial erase pulse
  func :erase_all

  # Deliver additional erase pulses as required until it verifies, maximum of 5 additional pulses
  5.times do |x|
    # Assign a unique id attribute to each verify so that we know which one we are talking about when
    # making other tests dependent on it.
    # When Origen sees the if_failed dependency on a future test it will be smart enough to inhibit the binning
    # on this test without having to explicitly declare that.
    func :margin_read1_all1, :id => "erase_vfy_#{x}"
    # Run this test only if the given verify failed
    func :erase_all, :if_failed => "erase_vfy_#{x}"
  end

  # A final verify to set the binning
  func :margin_read1_all1

  log 'Test if enable'
  func :erase_all, :if_enable => 'do_erase'

  if_enable 'do_erase' do
    func :erase_all
  end

  log 'Test unless enable'
  func :erase_all, :unless_enable => 'no_extra_erase'

  unless_enable 'no_extra_erase' do
    func :erase_all
    func :erase_all
  end

  func :erase_all
  func :erase_all

  log 'Test if_passed'
  func :erase_all, :id => 'erase_passed_1'
  func :erase_all, :id => 'erase_passed_2'

  func :margin_read1_all1, :if_passed => 'erase_passed_1'
  if_passed 'erase_passed_2' do
    func :margin_read1_all1
  end

  log 'Test unless_passed'
  func :erase_all, :id => 'erase_passed_3'
  func :erase_all, :id => 'erase_passed_4'

  func :margin_read1_all1, :unless_passed => 'erase_passed_3'
  unless_passed 'erase_passed_4' do
    func :margin_read1_all1
  end

  log 'Test if_failed'
  func :erase_all, :id => 'erase_failed_1'
  func :erase_all, :id => 'erase_failed_2'

  func :margin_read1_all1, :if_failed => 'erase_failed_1'
  if_failed 'erase_failed_2' do
    func :margin_read1_all1
  end

  log 'Test unless_failed'
  func :erase_all, :id => 'erase_failed_3'
  func :erase_all, :id => 'erase_failed_4'

  func :margin_read1_all1, :unless_failed => 'erase_failed_3'
  unless_failed 'erase_failed_4' do
    func :margin_read1_all1
  end

  log 'Test if_ran'
  func :erase_all, :id => 'erase_ran_1'
  func :erase_all, :id => 'erase_ran_2'

  func :margin_read1_all1, :if_ran => 'erase_ran_1'
  if_ran 'erase_ran_2' do
    func :margin_read1_all1
  end

  log 'Test unless_ran'
  func :erase_all, :id => 'erase_ran_3'
  func :erase_all, :id => 'erase_ran_4'

  func :margin_read1_all1, :unless_ran => 'erase_ran_3'
  unless_ran 'erase_ran_4' do
    func :margin_read1_all1
  end

  log 'Verify that job context wraps import'
  if_job :fr do
    import 'erase'
  end

  log 'Verify that job context wraps enable block within an import'
  if_job :fr do
    import 'additional_erase'
    import 'additional_erase', :force => true
  end

  log 'Verify that flow.cz works...'
  func :margin_read1_all1, :pin_levels => :cz, :cz_setup => 'vbplus_sweep'

  log 'Verify that flow.cz works with enable words'
  if_enable 'usb_xcvr_cz' do
    func :xcvr_fs_vilvih, cz_setup: 'usb_fs_vil_cz'
    func :xcvr_fs_vilvih, cz_setup: 'usb_fs_vih_cz'
  end

  func :xcvr_fs_vilvih, cz_setup: 'usb_fs_vil_cz', if_enable: 'usb_xcvr_cz'
  func :xcvr_fs_vilvih, cz_setup: 'usb_fs_vih_cz', if_enable: 'usb_xcvr_cz'

  log 'Verify that MTO template works...'
  mto_memory :mto_read1_all1

  if tester.uflex?
    log 'import statement'
    import 'components/temp' 

    log 'direct call'
    
    meas :bgap_voltage_meas, tnum: 1050, bin: 119, soft_bin: 2, hi_limit: 45
    meas :bgap_voltage_meas1
  end

  if tester.j750?
    meas :lo_voltage, tnum: 1150, bin: 95, soft_bin: 5
    meas :hi_voltage, pins: :hi_v, tnum: 1160, bin: 96, soft_bin: 6
    meas :ps_leakage, pins: :power, tnum: 1170, bin: 97, soft_bin: 6
  end

  log 'Speed binning example bug from video 5'
  group "200Mhz Tests", id: :g200 do
    test :test200_1
    test :test200_2
    test :test200_3
  end

  group "100Mhz Tests", if_failed: :g200, id: :g100 do
    test :test100_1, bin: 5
    test :test100_2, bin: 5
    test :test100_3, bin: 5
  end

  pass 2, if_ran: :g100

  pass 1, description: "Good die!", softbin: 1
end
