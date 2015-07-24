# The target file is run before *every* RGen operation and is used to instantiate
# the runtime environment - usually this means instantiating a top-level DUT
# object and a tester.
#
# Naming is arbitrary but instances names should be prefixed with $ which indicates a 
# global variable in Ruby, and this is required in order for the objects instantiated
# here to be visible throughout your application code.

$tester = Testers::J750.new   # Use Tester plug-in

$dut    = Testers::Test::DUT2.new   # Instantiate a DUT2 instance
$nvm    = Testers::Test::NVM.new    # Instantiate the NVM instance DUT2 uses

# You can also perform global configuration here, e.g. 
# $dut.do_something_before_every_job
