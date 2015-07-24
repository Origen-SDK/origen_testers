# An example of creating an entire test program from
# a single source file
Flow.create do

  self.resources_filename = 'prb2'

  func :erase_all, :duration => :dynamic

  func :margin_read1_all1

  func :erase_all, :duration => :dynamic
  func :margin_read1_all1

  import 'components/prb2_main'

  func :erase_all, :duration => :dynamic
  func :margin_read1_all1, :id => 'erased_successfully'

  skip :if_all_passed => 'erased_successfully' do
    import 'components/prb2_main'
  end

  if_enable 'extra_tests' do
    import 'components/prb2_main'
  end

  func :margin_read1_all1
  
  log '"Check OOF passcodes in both locations"'
  func :pgm_vfy_oof_passcode_tst, tname: "TST_VFY_OOF_PASSCODE", tnum: 1300, continue: true, id: :oof_passcode1
  func :pgm_vfy_oof_passcode_redcols_utst, tname: "UTST_VFY_OOF_PASSCODE_REDCOLS", tnum: 1300, continue: true, id: :oof_passcode2
  nop
  
  # Will create a better API when implementing this on V93K
  if RGen.tester.is_a?(Testers::IGXLBasedTester::Base)
    or_ids id1: :oof_passcode1, id2: :oof_passcode2, id: :OR, condition: :fail
    func :testme, tname: "", if_failed: :OR
  end
  
end
