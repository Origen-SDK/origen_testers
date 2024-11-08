hp93000,testflow,0.1
language_revision = 1;

testmethodparameters

tm_1:
  "BadPractice" = "NO";
  "Really.BadPractice" = "";
  "myArg0" = "arg0_set";
  "myArg1" = "a_default_value";
  "myArg2" = "CURR";
  "myArg3" = "arg3_set_from_finalize";
  "myArg4" = "arg4_set_from_method";
  "testName" = "Functional";
  "testerState" = "CONNECTED";
tm_2:
  "BadPractice" = "NO";
  "Really.BadPractice" = "";
  "myArg0" = "arg0_set";
  "myArg1" = "a_default_value";
  "myArg2" = "CURR";
  "myArg3" = "arg3_set_from_finalize";
  "myArg4" = "arg4_set_from_method";
  "testName" = "Functional";
  "testerState" = "CONNECTED";
tm_3:
  "BadPractice" = "NO";
  "Really.BadPractice" = "";
  "myArg0" = "arg0_set";
  "myArg1" = "a_default_value";
  "myArg2" = "CURR";
  "myArg3" = "arg3_set_from_finalize";
  "myArg4" = "arg4_set_from_method";
  "testName" = "Functional";
  "testerState" = "CONNECTED";
tm_4:
  "myArg0" = "arg0_set";
  "myArg1" = "b_default_value";
tm_5:
  "myArg0" = "arg1_should_not_render";
  "myArg2" = "VOLT";
  "testName" = "Functional";
  "testerState" = "CONNECTED";
tm_6:
  "myArg0" = "arg1_should_render";
  "myArg1" = "KEEP_ME";
  "myArg2" = "VOLT";
  "testName" = "Functional";
  "testerState" = "CONNECTED";
tm_7:
  "booleanArg" = "1";
  "booleanNoDefault" = "";
  "currentArg" = "1[A]";
  "currentNoDefault" = "";
  "doubleArg" = "5.22";
  "doubleNoDefault" = "";
  "frequencyArg" = "1000000[Hz]";
  "frequencyNoDefault" = "";
  "integerArg" = "5";
  "integerNoDefault" = "";
  "testName" = "Functional";
  "testerState" = "CONNECTED";
  "timeArg" = "10[s]";
  "timeNoDefault" = "";
  "voltageArg" = "1.2[V]";
  "voltageNoDefault" = "";

end
-----------------------------------------------------------------
testmethodlimits

tm_1:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_2:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_3:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_5:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_6:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_7:
  "Functional" = "":"NA":"":"NA":"":"":"";

end
-----------------------------------------------------------------
testmethods

tm_1:
  testmethod_class = "MyTml.TestA";
tm_2:
  testmethod_class = "MyTml.TestA";
tm_3:
  testmethod_class = "MyTml.TestA";
tm_4:
  testmethod_class = "MyTml.TestB";
tm_5:
  testmethod_class = "MyTml.TestC";
tm_6:
  testmethod_class = "MyTml.TestC";
tm_7:
  testmethod_class = "MyTml.TestD";

end
-----------------------------------------------------------------
test_flow

  {

  }, open,"CUSTOM_TESTS",""

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
