hp93000,testflow,0.1
language_revision = 1;

testmethodparameters

tm_1:
  "output" = "None";
  "testName" = "Functional";
tm_10:
  "output" = "None";
  "testName" = "Functional";
tm_11:
  "output" = "None";
  "testName" = "Functional";
tm_2:
  "output" = "None";
  "testName" = "Functional";
tm_3:
  "output" = "None";
  "testName" = "Functional";
tm_4:
  "output" = "None";
  "testName" = "Functional";
tm_5:
  "output" = "None";
  "testName" = "Functional";
tm_6:
  "output" = "None";
  "testName" = "Functional";
tm_7:
  "output" = "None";
  "testName" = "Functional";
tm_8:
  "output" = "None";
  "testName" = "Functional";
tm_9:
  "output" = "None";
  "testName" = "Functional";

end
-----------------------------------------------------------------
testmethodlimits

tm_1:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_10:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_11:
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

end
-----------------------------------------------------------------
testmethods

tm_1:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
tm_10:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
tm_11:
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

end
-----------------------------------------------------------------
test_suites

erase_all_1_814CEB0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "erase_all";
  override_testf = tm_3;
  site_control = "parallel:";
  site_match = 2;
erase_all_2_814CEB0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "erase_all";
  override_testf = tm_7;
  site_control = "parallel:";
  site_match = 2;
erase_all_814CEB0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "erase_all";
  override_testf = tm_1;
  site_control = "parallel:";
  site_match = 2;
margin_read1_all1_1_814CEB0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "margin_read1_all1";
  override_testf = tm_4;
  site_control = "parallel:";
  site_match = 2;
margin_read1_all1_2_814CEB0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "margin_read1_all1";
  override_testf = tm_8;
  site_control = "parallel:";
  site_match = 2;
margin_read1_all1_3_814CEB0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "margin_read1_all1";
  override_testf = tm_11;
  site_control = "parallel:";
  site_match = 2;
margin_read1_all1_814CEB0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "margin_read1_all1";
  override_testf = tm_2;
  site_control = "parallel:";
  site_match = 2;
mrd_ckbd_1_814CEB0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "mrd_ckbd";
  override_testf = tm_10;
  site_control = "parallel:";
  site_match = 2;
mrd_ckbd_814CEB0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "mrd_ckbd";
  override_testf = tm_6;
  site_control = "parallel:";
  site_match = 2;
pgm_ckbd_1_814CEB0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "pgm_ckbd";
  override_testf = tm_9;
  site_control = "parallel:";
  site_match = 2;
pgm_ckbd_814CEB0:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "pgm_ckbd";
  override_testf = tm_5;
  site_control = "parallel:";
  site_match = 2;

end
-----------------------------------------------------------------
test_flow

  {
  if @PRB2_ENABLE == 1 then
  {
    run(erase_all_814CEB0);
    run(margin_read1_all1_814CEB0);
    run(erase_all_1_814CEB0);
    run(margin_read1_all1_1_814CEB0);
    {
      run(pgm_ckbd_814CEB0);
      run(mrd_ckbd_814CEB0);
    }, open,"prb2_main", ""
    run(erase_all_2_814CEB0);
    run(margin_read1_all1_2_814CEB0);
    if @EXTRA_TESTS == 1 then
    {
      {
        run(pgm_ckbd_1_814CEB0);
        run(mrd_ckbd_1_814CEB0);
      }, open,"prb2_main_2", ""
    }
    else
    {
    }
    run(margin_read1_all1_3_814CEB0);
  }
  else
  {
  }

  }, open,"PRB2","An example of creating an entire test program from a single source file"

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
