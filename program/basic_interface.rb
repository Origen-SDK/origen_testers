Flow.create interface: 'OrigenTesters::Test::BasicInterface' do

  functional :test1, sbin: 100, number: 20000

  # test multi limit support if uflex, not sure what platforms support this or the syntax
  if tester.uflex?
    functional :test2, sbin: 101, number: 20020, lo: [-2, -1], hi: [2, 1], limit_tname: ['lim1', 'lim2']
  end

end
