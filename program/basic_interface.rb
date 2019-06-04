Flow.create interface: 'OrigenTesters::Test::BasicInterface' do

  functional :test1, sbin: 100, number: 20000

  # test multi limit support if uflex, not sure what platforms support this or the syntax
  if tester.uflex?
    functional :test2, sbin: 101, number: 20020,
      sub_tests: [
        sub_test(:lim1, lo: -2, hi: 2),
        sub_test(:lim2, lo: -1, hi: 1)
      ]
  end

end
