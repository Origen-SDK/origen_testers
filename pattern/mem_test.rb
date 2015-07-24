unless $tester.v93k?
  # Pattern to exercise the memory test feature of tester
  Pattern.create(:memory_test => true) do
    
    $dut.memory_test
    
  end
end
