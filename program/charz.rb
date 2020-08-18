# An instance of the interface is
# passed in here, iterators and other
# argument passing will be supported
# similar to Pattern.create.
Flow.create interface: 'OrigenTesters::Test::Interface' do
  flow.flow_description = '' if tester.v93k?

  if tester.v93k? && tester.smt7?
    charz_on :complex_gates
    func_with_charz :func_complex_gates
    charz_off

    charz_on :cz_only, { placement: :eof }
    func_with_charz :func_charz_only
    charz_off

    func_with_charz :func_test_level_routine, charz: [:routine1, { type: :routine }]
  end

end
