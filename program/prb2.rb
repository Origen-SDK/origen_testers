# An example of creating an entire test program from
# a single source file
Flow.create interface: 'OrigenTesters::Test::Interface', flow_bypass: true do

  # Test that this can be overridden from the target at flow-level
  self.add_flow_enable = :enabled

  unless Origen.app.environment.name == 'v93k_global'
    self.resources_filename = 'prb2'
  end

  func :erase_all, duration: :dynamic, number: 10000

  func :margin_read1_all1, number: 10010

  func :erase_all, duration: :dynamic, number: 10020
  func :margin_read1_all1, number: 10030

  import 'components/prb2_main', number: 11000

  func :erase_all, duration: :dynamic, number: 12000
  func :margin_read1_all1, id: 'erased_successfully', number: 12010

  if_enable 'extra_tests' do
    import 'components/prb2_main', number: 13000
  end

  func :margin_read1_all1, number: 14000
end
