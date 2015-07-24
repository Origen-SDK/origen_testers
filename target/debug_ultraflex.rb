# Production mode will require that there are no modified files in the workspace
# and any other conditions that you add to your application.
# Normally production targets define the target and then debug targets
# are setup to load the production target before switching RGen to debug
# mode as shown below.
load "#{RGen.root}/target/production_ultraflex.rb"
$tester.assign_dc_instr_pins([$dut.hv_supply_pin, $dut.lv_supply_pin])
$tester.memory_test_en = true
RGen.mode = :debug
