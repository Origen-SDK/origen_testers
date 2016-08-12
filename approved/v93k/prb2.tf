hp93000,testflow,0.1
language_revision = 1;
 
information
 
-- STOPDIFF
test_revision = "0.5.6";
-- STARTDIFF
 
end
--------------------------------------------------
declarations

@EXTRA_TESTS = -1;
end
--------------------------------------------------
implicit_declarations

end
-----------------------------------------------------------------
flags

datalog_formatter = 0;
datalog_sample_size = 1;
graphic_result_displa = 1;
state_display = 0;
print_wafermap = 0;
ink_wafer = 0;
max_reprobes = 1;
temp_monitor = 1;
calib_age_monitor = 1;
diag_monitor = 1;
current_monitor = 1;
log_events_enable = 1;
set_pass_level = 0;
set_fail_level = 0;
set_bypass_level = 0;
hold_on_fail = 0;
global_hold = 0;
debug_mode = 0;
debug_analog = 0;
parallel_mode = 1;
site_match_mode = 2;
global_overon = 0;
limits_enable = 0;
test_number_enable = 1;
test_number_inc = 1;
log_cycles_before = 0;
log_cycles_after = 0;
unburst_mode = 0;
sqst_mode = 0;
warn_as_fail = 1;
use_hw_dsp = 0;
dsp_file_enable = 0;
buffer_testflow_log = 0;
check_testmethod_api = 0;
stdf_generation = 1;
tm_crash_as_fatal = 1;
hidden_datalog_mode = 0;
multibin_mode = 0;
end
-----------------------------------------------------------------
testmethodparameters
tm_1:
  "testName" = "Functional";
  "output" = "None";
tm_2:
  "testName" = "Functional";
  "output" = "None";
tm_3:
  "testName" = "Functional";
  "output" = "None";
tm_4:
  "testName" = "Functional";
  "output" = "None";
tm_5:
  "testName" = "Functional";
  "output" = "None";
tm_6:
  "testName" = "Functional";
  "output" = "None";
tm_7:
  "testName" = "Functional";
  "output" = "None";
tm_8:
  "testName" = "Functional";
  "output" = "None";
tm_9:
  "testName" = "Functional";
  "output" = "None";
tm_10:
  "testName" = "Functional";
  "output" = "None";
tm_11:
  "testName" = "Functional";
  "output" = "None";
end
--------------------------------------------------
testmethodlimits
tm_1:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_2:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_3:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_4:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_5:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_6:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_7:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_8:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_9:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_10:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_11:
  "Functional" = "":"NA":"":"NA":"":"":"";
end
--------------------------------------------------
testmethods
tm_1:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
tm_2:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
tm_3:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
tm_4:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
tm_5:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
tm_6:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
tm_7:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
tm_8:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
tm_9:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
tm_10:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
tm_11:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
end
--------------------------------------------------
test_suites
erase_all:
  override = 1;
 override_seqlbl = "erase_all";
 override_testf = tm_1;
local_flags  = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
 site_match = 2;
 site_control = "parallel:";
margin_read1_all1:
  override = 1;
 override_seqlbl = "margin_read1_all1";
 override_testf = tm_2;
local_flags  = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
 site_match = 2;
 site_control = "parallel:";
erase_all_1:
  override = 1;
 override_seqlbl = "erase_all";
 override_testf = tm_3;
local_flags  = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
 site_match = 2;
 site_control = "parallel:";
margin_read1_all1_1:
  override = 1;
 override_seqlbl = "margin_read1_all1";
 override_testf = tm_4;
local_flags  = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
 site_match = 2;
 site_control = "parallel:";
pgm_ckbd:
  override = 1;
 override_seqlbl = "pgm_ckbd";
 override_testf = tm_5;
local_flags  = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
 site_match = 2;
 site_control = "parallel:";
mrd_ckbd:
  override = 1;
 override_seqlbl = "mrd_ckbd";
 override_testf = tm_6;
local_flags  = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
 site_match = 2;
 site_control = "parallel:";
erase_all_2:
  override = 1;
 override_seqlbl = "erase_all";
 override_testf = tm_7;
local_flags  = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
 site_match = 2;
 site_control = "parallel:";
margin_read1_all1_2:
  override = 1;
 override_seqlbl = "margin_read1_all1";
 override_testf = tm_8;
local_flags  = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
 site_match = 2;
 site_control = "parallel:";
pgm_ckbd_1:
  override = 1;
 override_seqlbl = "pgm_ckbd";
 override_testf = tm_9;
local_flags  = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
 site_match = 2;
 site_control = "parallel:";
mrd_ckbd_1:
  override = 1;
 override_seqlbl = "mrd_ckbd";
 override_testf = tm_10;
local_flags  = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
 site_match = 2;
 site_control = "parallel:";
margin_read1_all1_3:
  override = 1;
 override_seqlbl = "margin_read1_all1";
 override_testf = tm_11;
local_flags  = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
 site_match = 2;
 site_control = "parallel:";
end
--------------------------------------------------
test_flow
{
}, open,"Init Flow Control Vars", ""
run(erase_all);
run(margin_read1_all1);
run(erase_all_1);
run(margin_read1_all1_1);
{
  run(pgm_ckbd);
  run(mrd_ckbd);
}, open,"prb2_main", ""
run(erase_all_2);
run(margin_read1_all1_2);
{
  if @EXTRA_TESTS == 1 then
  {
    run(pgm_ckbd_1);
    run(mrd_ckbd_1);
  }
  else
  {
  }
}, open,"prb2_main_2", ""
run(margin_read1_all1_3);
end
-------------------------------------------------
binning
otherwise bin = "db", "", , bad, noreprobe, red, , not_over_on;
end
-------------------------------------------------
context
 
end
--------------------------------------------------
hardware_bin_descriptions
end
