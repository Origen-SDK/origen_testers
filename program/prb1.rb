# An instance of the interface is
# passed in here, iterators and other
# argument passing will be supported
# similar to Pattern.create.
Flow.create interface: 'OrigenTesters::Test::Interface' do

  self.resources_filename = 'prb1'

  import 'components/prb1_main'

  # Test that a reference to a deeply nested test works (mainly for SMT8)
  test :on_deep_1, if_failed: :deep_test

  pass 1, description: "Good die!", softbin: 1
end
