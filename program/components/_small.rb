Flow.create do |options|

  test :test1, if_enable: :small_flow, number: options[:number] + 10
  test :test2, if_enable: :small_flow, number: options[:number] + 20
  test :test1, number: options[:number] + 30
  test :test1, number: options[:number] + 40
  test :test1, number: options[:number] + 50
  test :test1, number: options[:number] + 60
  test :test1, number: options[:number] + 70
  test :test1, number: options[:number] + 80
  test :test1, number: options[:number] + 90
  test :test1, if_enable: :small_flow, number: options[:number] + 100
  test :test2, if_enable: :small_flow, number: options[:number] + 110

end
