# An instance of the interface is
# passed in here, iterators and other
# argument passing will be supported
# similar to Pattern.create.
Flow.create interface: 'OrigenTesters::Test::Interface' do

  self.resources_filename = 'prb1'

  #import 'components/prb1_main'
    func :margin_read1_all1, :id => "erase_vfy"
    # Run this test only if the given verify failed
    func :erase_all, :if_failed => "erase_vfy"

end
