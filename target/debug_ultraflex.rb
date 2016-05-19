# Production mode will require that there are no modified files in the workspace
# and any other conditions that you add to your application.
# Normally production targets define the target and then debug targets
# are setup to load the production target before switching Origen to debug
# mode as shown below.
load "#{Origen.root}/target/production_ultraflex.rb"
$tester.assign_dc_instr_pins([$dut.hv_supply_pin, $dut.lv_supply_pin])
#$tester.assign_digsrc_pins($dut.digsrc_pins)  #pins handled by apply_digsrc_settings
$tester.apply_digsrc_settings($dut.pin(:tdi), $dut.pin(:tms), $dut.digsrc_settings)
#$tester.assign_digcap_pins($dut.digcap_pins)  #pins handled by apply_digcap_settings
$tester.apply_digcap_settings($dut.pin(:tdo), $dut.digcap_settings)
$tester.memory_test_en = true
Origen.mode = :debug
