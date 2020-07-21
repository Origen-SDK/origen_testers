# An instance of the interface is
# passed in here, iterators and other
# argument passing will be supported
# similar to Pattern.create.
Flow.create interface: 'OrigenTesters::Test::Interface', flow_description: 'Probe1 Main' do

  unless Origen.app.environment.name == 'v93k_global'
    self.resources_filename = 'prb1'
  end

  import 'components/prb1_main'

  import 'test' # import top-level test.rb directly, note that Flow.create options of sub-flow will be ignored!

  # Test that a reference to a deeply nested test works (mainly for SMT8)
  test :on_deep_1, if_failed: :deep_test, test_text: "some_custom_text"

  pass 1, description: "Good die!", softbin: 1
end
