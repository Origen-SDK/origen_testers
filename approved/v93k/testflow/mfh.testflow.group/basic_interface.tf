hp93000,testflow,0.1
language_revision = 1;

testmethodparameters

tm_1:
  "output" = "None";
  "testName" = "Functional";

end
-----------------------------------------------------------------
testmethodlimits

tm_1:
  "Functional" = "":"NA":"":"NA":"":"":"";

end
-----------------------------------------------------------------
testmethods

tm_1:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";

end
-----------------------------------------------------------------
test_suites

test1_9D2D940:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_levset = "Lvl";
  override_seqlbl = "test1";
  override_testf = tm_1;
  override_timset = "Tim";
  site_control = "parallel:";
  site_match = 2;

end
-----------------------------------------------------------------
test_flow

  {
    run_and_branch(test1_9D2D940)
    then
    {
    }
    else
    {
       stop_bin "100", "fail", , bad, noreprobe, red, 3, over_on;
    }

  }, open,"BASIC_INTERFACE",""

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
