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
  "testerState" = "CONNECTED";
  "testName" = "Functional";
  "myArg0" = "arg0_set";
  "myArg1" = "a_default_value";
  "myArg2" = "CURR";
  "myArg3" = "arg3_set_from_finalize";
  "myArg4" = "arg4_set_from_method";
  "BadPractice" = "NO";
  "Really.BadPractice" = "";
tm_2:
  "testerState" = "CONNECTED";
  "testName" = "Functional";
  "myArg0" = "arg0_set";
  "myArg1" = "a_default_value";
  "myArg2" = "CURR";
  "myArg3" = "arg3_set_from_finalize";
  "myArg4" = "arg4_set_from_method";
  "BadPractice" = "NO";
  "Really.BadPractice" = "";
tm_3:
  "testerState" = "CONNECTED";
  "testName" = "Functional";
  "myArg0" = "arg0_set";
  "myArg1" = "a_default_value";
  "myArg2" = "CURR";
  "myArg3" = "arg3_set_from_finalize";
  "myArg4" = "arg4_set_from_method";
  "BadPractice" = "NO";
  "Really.BadPractice" = "";
end
--------------------------------------------------
testmethodlimits
tm_1:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_2:
  "Functional" = "":"NA":"":"NA":"":"":"";
tm_3:
  "Functional" = "":"NA":"":"NA":"":"":"";
end
--------------------------------------------------
testmethods
tm_1:
  testmethod_class = "MyTml.TestA";
tm_2:
  testmethod_class = "MyTml.TestA";
tm_3:
  testmethod_class = "MyTml.TestA";
end
--------------------------------------------------
test_suites
end
--------------------------------------------------
test_flow
{
}, open,"CUSTOM_TESTS", ""
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
