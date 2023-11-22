# An instance of the interface is
# passed in here, iterators and other
# argument passing will be supported
# similar to Pattern.create.
Flow.create interface: 'OrigenTesters::Test::Interface' do
  flow.flow_description = '' if tester.v93k?

  if tester.v93k? && tester.smt7?
    charz_on :complex_gates, { on_result: :fail }
      func_with_charz :func_complex_gates_on_fail
    charz_off

    charz_on :complex_gates, { enables: :my_enable }
      func_with_charz :func_complex_flag_simple_enable
    charz_off

    charz_on :complex_gates, { flags: :my_flag } do
      func_with_charz :func_complex_enable_simple_flag
    end

    charz_on :cz_only, { placement: :eof }
      func_with_charz :func_charz_only
    charz_off

    func_with_charz :func_test_level_routine, charz: [:routine1, { type: :routine }]

    charz_on :cz
      func_with_charz :func_skip_group, skip_group: true
      charz_pause
      func_with_charz :func_pause_charz
      charz_resume
      func_with_charz :func_resume_charz
    charz_off

    charz_on :simple_gates, { on_result: :pass } do 
      func_with_charz :func_simple_gates_on_pass
    end
    
    charz_on :simple_gates, { enables: nil }
    func_with_charz :func_simple_flags
    charz_off

    charz_on :simple_gates, { flags: nil }
    func_with_charz :func_simple_enables
    charz_off

    charz_on :simple_anded_flags, { flags: { routine1: [:my_flag1, :my_flag2]}}
    func_with_charz :func_simple_anded_flags
    charz_off

    charz_on :simple_anded_enables, {enables: { routine1: [:my_enable1, :my_enable2]}}
      func_with_charz :func_simple_anded_enables
    charz_off
    
    charz_on :complex_anded_flags, {flags: { routine1: [:my_flag1, :my_flag2]}}
      func_with_charz :func_complex_anded_flags
      charz_on_append :routine2, { type: :routine }
      func_with_charz :func_complex_anded_flags_add_simple_rt2
      charz_off_truncate
    charz_off

    charz_on :complex_anded_enables, {enables: { routine1: [:my_enable1, :my_enable2]}}
      func_with_charz :func_complex_anded_enables
    charz_off

    

  end
end
