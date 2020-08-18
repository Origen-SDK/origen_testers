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

func_charz_only_E4F9C4F:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "func_charz_only";
  override_testf = tm_8;
  site_control = "parallel:";
  site_match = 2;
func_charz_only__cz__rt1_E4F9C4F:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "func_charz_only__cz__rt1";
  override_testf = tm_11;
  site_control = "parallel:";
  site_match = 2;
func_complex_gates_E4F9C4F:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "func_complex_gates";
  override_testf = tm_1;
  site_control = "parallel:";
  site_match = 2;
func_complex_gates__cz__rt1_E4F9C4F:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "func_complex_gates__cz__rt1";
  override_testf = tm_3;
  site_control = "parallel:";
  site_match = 2;
func_complex_gates__cz__rt2_E4F9C4F:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "func_complex_gates__cz__rt2";
  override_testf = tm_4;
  site_control = "parallel:";
  site_match = 2;
func_complex_gates__cz__rt3_E4F9C4F:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "func_complex_gates__cz__rt3";
  override_testf = tm_5;
  site_control = "parallel:";
  site_match = 2;
func_complex_gates__cz__rt4_E4F9C4F:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "func_complex_gates__cz__rt4";
  override_testf = tm_6;
  site_control = "parallel:";
  site_match = 2;
func_complex_gates__cz__rt5_E4F9C4F:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "func_complex_gates__cz__rt5";
  override_testf = tm_7;
  site_control = "parallel:";
  site_match = 2;
func_complex_gates__cz__rt6_E4F9C4F:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "func_complex_gates__cz__rt6";
  override_testf = tm_2;
  site_control = "parallel:";
  site_match = 2;
func_test_level_routine_E4F9C4F:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "func_test_level_routine";
  override_testf = tm_9;
  site_control = "parallel:";
  site_match = 2;
func_test_level_routine__cz__rt1_E4F9C4F:
  local_flags = output_on_pass, output_on_fail, value_on_pass, value_on_fail, per_pin_on_pass, per_pin_on_fail;
  override = 1;
  override_seqlbl = "func_test_level_routine__cz__rt1";
  override_testf = tm_10;
  site_control = "parallel:";
  site_match = 2;

end
-----------------------------------------------------------------
test_flow

  {
    {
       @FUNC_COMPLEX_GATES_CHARZ_COMPLEX_GATES_E4F9C4F_FAILED = -1;
    }, open,"Init Flow Control Vars", ""
    run_and_branch(func_complex_gates_E4F9C4F)
    then
    {
    }
    else
    {
       @FUNC_COMPLEX_GATES_CHARZ_COMPLEX_GATES_E4F9C4F_FAILED = 1;
    }
    {
       if @FUNC_COMPLEX_GATES_CHARZ_COMPLEX_GATES_E4F9C4F_FAILED == 1 then
       {
          run(func_complex_gates__cz__rt6_E4F9C4F);
          if @MyFlag1 == 1 then
          {
             if @MyEnable1 == 1 then
             {
                run(func_complex_gates__cz__rt1_E4F9C4F);
             }
             else
             {
             }
             if @MyEnable2 == 1 then
             {
                run(func_complex_gates__cz__rt2_E4F9C4F);
             }
             else
             {
             }
          }
          else
          {
          }
          if @MyEnable2 == 1 then
          {
             if @MyFlag2 == 1 then
             {
                run(func_complex_gates__cz__rt3_E4F9C4F);
             }
             else
             {
             }
          }
          else
          {
          }
          if @MyFlag3 == 1 then
          {
             run(func_complex_gates__cz__rt4_E4F9C4F);
          }
          else
          {
          }
          if @MyEnable3 == 1 then
          {
             run(func_complex_gates__cz__rt5_E4F9C4F);
          }
          else
          {
          }
       }
       else
       {
       }
    }, open,"func_complex_gates charz complex_gates", ""
    run(func_test_level_routine_E4F9C4F);
    {
       run(func_test_level_routine__cz__rt1_E4F9C4F);
    }, open,"func_test_level_routine charz _cz__rt1", ""
    {
       {
          run(func_charz_only__cz__rt1_E4F9C4F);
       }, open,"func_charz_only charz cz_only", ""
    }, open,"End of Flow Charz Tests", ""

  }, open,"CHARZ",""

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
