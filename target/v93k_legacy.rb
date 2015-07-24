# This target is used to run the legacy test patterns from Origen core
$dut    = OrigenTesters::Test::DUT2.new
$nvm    = OrigenTesters::Test::NVM.new    # Instantiate the NVM instance DUT2 uses
$tester = OrigenTesters::V93K.new

Origen.mode = :debug
