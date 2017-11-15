Flow.create do |options|

  test :test1, if_enable: :small_flow
  test :test2, if_enable: :small_flow
  test :test1
  test :test1
  test :test1
  test :test1
  test :test1
  test :test1
  test :test1
  test :test1, if_enable: :small_flow
  test :test2, if_enable: :small_flow

end
