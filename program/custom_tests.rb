# This flow is used to test custom test method API
Flow.create interface: 'OrigenTesters::Test::CustomTestInterface', flow_description: '' do

  custom :test1, number: 30000

  custom :test2, number: 30010

  custom :test3, number: 30020

  if tester.v93k?
    custom_b :test4, number: 30040
    if tester.smt8?
      custom_hash :test5, number: 30050
    end

    custom_c :test6, number: 30060
    custom_c :test7, number: 30070, my_arg1: 'KEEP_ME'
  end
end
