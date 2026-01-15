hp93000,testflow,0.1
language_revision = 1;

testmethodparameters
end
-----------------------------------------------------------------
testmethodlimits
end
-----------------------------------------------------------------
test_flow

  {
    {
       @My_Mixed_Flag = -1;
    }, open,"Init Flow Control Vars", ""
    print_dl("Mixed-case manual flags");
    run_and_branch(test1)
    then
    {
    }
    else
    {
       @My_Mixed_Flag = 1;
    }
    if @My_Mixed_Flag == 1 then
    {
       run(test2);
    }
    else
    {
       run(test3);
    }
    print_dl("Mixed-case manual flags - induce frozen string error");
    run_and_branch(test4)
    then
    {
    }
    else
    {
       @My_Mixed_Flag = 1;
    }
    if @My_Mixed_Flag == 1 then
    {
       run(test5);
    }
    else
    {
       run(test6);
    }

  }, open,"Flow Control Testing","Flow to exercise the Flow Control API"

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
