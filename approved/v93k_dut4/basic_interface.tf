hp93000,testflow,0.1
language_revision = 1;
 
information
 
 
end
--------------------------------------------------
implicit_declarations

end
-----------------------------------------------------------------
testmethodparameters
tm_1:
  "testName" = "Functional";
  "output" = "None";
end
--------------------------------------------------
testmethodlimits
tm_1:
  "Functional" = "":"NA":"":"NA":"":"":"";
end
--------------------------------------------------
testmethods
tm_1:
  testmethod_class = "ac_tml.AcTest.FunctionalTest";
end
--------------------------------------------------
test_suites
test1_9D2D940:
  override = 1;
 override_timset = "Tim";
 override_levset = "Lvl";
 override_seqlbl = "test1_pset";
 override_testf = tm_1;
local_flags  = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
 site_match = 2;
 site_control = "parallel:";
end
--------------------------------------------------
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
}, open,"BASIC_INTERFACE", ""
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
