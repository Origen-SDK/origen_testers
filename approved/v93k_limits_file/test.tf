hp93000,testflow,0.1
language_revision = 1;

testmethodparameters

tm_1:
  "forceMode" = "VOLT";
  "forceValue" = "3.8[V]";
  "measureMode" = "PPMUpar";
  "output" = "None";
  "pinlist" = "@";
  "ppmuClampHigh" = "0[V]";
  "ppmuClampLow" = "0[V]";
  "precharge" = "OFF";
  "prechargeVoltage" = "0[V]";
  "relaySwitchMode" = "DEFAULT(BBM)";
  "settlingTime" = "0[s]";
  "spmuClamp" = "0[A]";
  "termination" = "OFF";
  "testName" = "passLimit_uA_mV";
  "testerState" = "CONNECTED";
tm_2:
  "forceMode" = "VOLT";
  "forceValue" = "3.8[V]";
  "measureMode" = "PPMUpar";
  "output" = "None";
  "pinlist" = "@";
  "ppmuClampHigh" = "0[V]";
  "ppmuClampLow" = "0[V]";
  "precharge" = "OFF";
  "prechargeVoltage" = "0[V]";
  "relaySwitchMode" = "DEFAULT(BBM)";
  "settlingTime" = "0[s]";
  "spmuClamp" = "0[A]";
  "termination" = "OFF";
  "testName" = "passLimit_uA_mV";
  "testerState" = "CONNECTED";
tm_3:
  "forceMode" = "VOLT";
  "forceValue" = "3.8[V]";
  "measureMode" = "PPMUpar";
  "output" = "None";
  "pinlist" = "@";
  "ppmuClampHigh" = "0[V]";
  "ppmuClampLow" = "0[V]";
  "precharge" = "OFF";
  "prechargeVoltage" = "0[V]";
  "relaySwitchMode" = "DEFAULT(BBM)";
  "settlingTime" = "0[s]";
  "spmuClamp" = "0[A]";
  "termination" = "OFF";
  "testName" = "passLimit_uA_mV";
  "testerState" = "CONNECTED";
tm_4:
  "forceMode" = "VOLT";
  "forceValue" = "3.8[V]";
  "measureMode" = "PPMUpar";
  "output" = "None";
  "pinlist" = "@";
  "ppmuClampHigh" = "0[V]";
  "ppmuClampLow" = "0[V]";
  "precharge" = "OFF";
  "prechargeVoltage" = "0[V]";
  "relaySwitchMode" = "DEFAULT(BBM)";
  "settlingTime" = "0[s]";
  "spmuClamp" = "0[A]";
  "termination" = "OFF";
  "testName" = "passLimit_uA_mV";
  "testerState" = "CONNECTED";
tm_5:
  "forceMode" = "VOLT";
  "forceValue" = "3.8[V]";
  "measureMode" = "PPMUpar";
  "output" = "None";
  "pinlist" = "@";
  "ppmuClampHigh" = "0[V]";
  "ppmuClampLow" = "0[V]";
  "precharge" = "OFF";
  "prechargeVoltage" = "0[V]";
  "relaySwitchMode" = "DEFAULT(BBM)";
  "settlingTime" = "0[s]";
  "spmuClamp" = "0[A]";
  "termination" = "OFF";
  "testName" = "passLimit_uA_mV";
  "testerState" = "CONNECTED";
tm_6:
  "forceMode" = "VOLT";
  "forceValue" = "3.8[V]";
  "measureMode" = "PPMUpar";
  "output" = "None";
  "pinlist" = "@";
  "ppmuClampHigh" = "0[V]";
  "ppmuClampLow" = "0[V]";
  "precharge" = "OFF";
  "prechargeVoltage" = "0[V]";
  "relaySwitchMode" = "DEFAULT(BBM)";
  "settlingTime" = "0[s]";
  "spmuClamp" = "0[A]";
  "termination" = "OFF";
  "testName" = "passLimit_uA_mV";
  "testerState" = "CONNECTED";
tm_7:
  "forceMode" = "VOLT";
  "forceValue" = "3.8[V]";
  "measureMode" = "PPMUpar";
  "output" = "None";
  "pinlist" = "@";
  "ppmuClampHigh" = "0[V]";
  "ppmuClampLow" = "0[V]";
  "precharge" = "OFF";
  "prechargeVoltage" = "0[V]";
  "relaySwitchMode" = "DEFAULT(BBM)";
  "settlingTime" = "0[s]";
  "spmuClamp" = "0[A]";
  "termination" = "OFF";
  "testName" = "passLimit_uA_mV";
  "testerState" = "CONNECTED";

end
-----------------------------------------------------------------
testmethodlimits


end
-----------------------------------------------------------------
testmethods

tm_1:
  testmethod_class = "dc_tml.DcTest.GeneralPMU";
tm_2:
  testmethod_class = "dc_tml.DcTest.GeneralPMU";
tm_3:
  testmethod_class = "dc_tml.DcTest.GeneralPMU";
tm_4:
  testmethod_class = "dc_tml.DcTest.GeneralPMU";
tm_5:
  testmethod_class = "dc_tml.DcTest.GeneralPMU";
tm_6:
  testmethod_class = "dc_tml.DcTest.GeneralPMU";
tm_7:
  testmethod_class = "dc_tml.DcTest.GeneralPMU";

end
-----------------------------------------------------------------
test_suites

meas_read_pump_1_2D155E0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "meas_read_pump";
  override_testf = tm_2;
  site_control = "parallel:";
  site_match = 2;
meas_read_pump_2D155E0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "meas_read_pump";
  override_testf = tm_1;
  site_control = "parallel:";
  site_match = 2;
meas_read_pump_2_2D155E0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "meas_read_pump";
  override_testf = tm_3;
  site_control = "parallel:";
  site_match = 2;
meas_read_pump_3_2D155E0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "meas_read_pump";
  override_testf = tm_4;
  site_control = "parallel:";
  site_match = 2;
meas_read_pump_4_2D155E0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "meas_read_pump";
  override_testf = tm_5;
  site_control = "parallel:";
  site_match = 2;
meas_read_pump_5_2D155E0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "meas_read_pump";
  override_testf = tm_6;
  site_control = "parallel:";
  site_match = 2;
meas_read_pump_6_2D155E0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "meas_read_pump";
  override_testf = tm_7;
  site_control = "parallel:";
  site_match = 2;

end
-----------------------------------------------------------------
test_flow

  {
  run_and_branch(meas_read_pump_2D155E0)
  then
  {
  }
  else
  {
    multi_bin;
  }
  run_and_branch(meas_read_pump_1_2D155E0)
  then
  {
  }
  else
  {
    multi_bin;
  }
  run_and_branch(meas_read_pump_2_2D155E0)
  then
  {
  }
  else
  {
    multi_bin;
  }
  run_and_branch(meas_read_pump_3_2D155E0)
  then
  {
  }
  else
  {
    multi_bin;
  }
  run_and_branch(meas_read_pump_4_2D155E0)
  then
  {
  }
  else
  {
    multi_bin;
  }
  run(meas_read_pump_5_2D155E0);
  run(meas_read_pump_6_2D155E0);

  }, open,"TEST",""

end
-----------------------------------------------------------------
binning
end
-----------------------------------------------------------------
oocrule


end
-----------------------------------------------------------------
context


end
-----------------------------------------------------------------
hardware_bin_descriptions


end
-----------------------------------------------------------------
