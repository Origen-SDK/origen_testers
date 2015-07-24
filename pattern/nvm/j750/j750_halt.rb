# This pattern exercises the methods in the Origen::Tester::J750 class
Pattern.create(:end_with_halt => true) do

  ss 'Test that basic cycling works'
  $tester.cycle
  10.times do
    $nvm.pin(:invoke).drive(1)
    $tester.cycle
  end
  10.times do |i|
    $nvm.pin(:invoke).drive(i.even? ? 0 : 1)
    $tester.cycle
  end

  ss 'Test that basic port manipulation works'
  unless $tester.respond_to?('hpt_mode')
    $nvm.port(:porta).drive(0x55)
    $tester.cycle
    $nvm.port(:porta).expect(0xAA)
    $tester.cycle
    $nvm.port(:porta)[1].dont_care
    $tester.cycle
  end

  ss 'Test that the store method works'
  cc 'This vector should be stored'
  $tester.cycle
  $tester.store
  $tester.cycle
  cc 'This vector should be stored'
  $tester.cycle
  $tester.cycle
  $tester.cycle
  $tester.store(:offset => -2)

  ss 'Test calling a subroutine'
  cc "This vector should call subroutine 'sub1'"
  $tester.cycle
  $tester.call_subroutine('sub1')
  cc "This vector should call subroutine 'sub2'"
  $tester.cycle
  $tester.cycle
  $tester.call_subroutine('sub2', :offset => -1)
  cc "This vector should call subroutine 'sub3', however because"
  cc 'it is local it should not appear in the imports in the header'
  $tester.cycle
  $tester.call_subroutine('sub3')

  ss 'Test generating a handshake inside a subroutine'
  cc "The next line should have a global label 'sub3', but no vector"
  $tester.start_subroutine('sub3')
  $tester.handshake
  cc 'This vector should have a return statement'
  $tester.cycle
  $tester.end_subroutine

  ss 'Test generating a handshake with a readcode'
  $tester.handshake(:readcode => 10)

  ss 'Test frequency counter'
  $tester.freq_count($nvm.pin(:dtst), :readcode => 33)

  ss 'Test a single pin match loop'
  $tester.wait(:match => true, :time_in_us => 5000, :pin => $nvm.pin(:done), :state => :high)

  ss 'Test a two pin match loop'
  $tester.wait(:match => true, :time_in_us => 5000,
               :pin => $nvm.pin(:done), :state => :high,
               :pin2 => $nvm.pin(:fail), :state2 => :low)

  ss 'Test adding an arbitrary label'
  $tester.cycle
  $tester.label 'a_test_label'
  $tester.cycle

  ss 'Test calling a match loop'
  $tester.cycle
  $tester.call_match
  $tester.cycle
  $tester.call_match

  ss 'Test setting the readcode to 100'
  $tester.set_code(100)

  ss 'Test explicit branching'
  $tester.branch_to('somewhere')

  if !$tester.respond_to?('hpt_mode')
    ss 'Test looping, these vectors should be executed once'
    $tester.loop_vector('test_loop_1', 1) do
      $nvm.port(:porta).drive(0xAA)
      $tester.cycle
      $nvm.port(:porta).drive(0x55)
      $tester.cycle
    end

    ss 'Test looping, these vectors should be executed 3 times'
    $tester.loop_vector('test_loop_2', 3) do
      $nvm.port(:porta).drive(0xAA)
      $tester.cycle
      $nvm.port(:porta).drive(0x55)
      $tester.cycle
    end
  else
    ss 'Test looping, these vectors should be executed once'
    $tester.loop_vector('test_loop_1', 1) do
      $nvm.pin(:clk).drive(1)
      $tester.cycle
      $nvm.pin(:clk).drive(0)
      $tester.cycle
    end

    ss 'Test looping, these vectors should be executed 3 times'
    $tester.loop_vector('test_loop_2', 3) do
      $nvm.pin(:clk).drive(1)
      $tester.cycle
      $nvm.pin(:clk).drive(0)
      $tester.cycle
    end
  end

  ss 'Test repeat_previous'
  $tester.cycle
  cc 'Invoke should repeat previous for 10 cycles'
  $nvm.pin(:invoke).repeat_previous = true
  10.cycles
  $nvm.pin(:invoke).repeat_previous = false
  cc 'All pins should repeat previous for 10 cycles, except the clk pin'
  $tester.repeat_previous do
    $nvm.pin(:clk).drive(1)
    10.cycles
  end
  cc 'All should return to the original state'
  $tester.cycle

  ss 'Test suspend compares'
  $nvm.pin(:fail).assert!(1)
  cc 'The fail pin should not be compared on these vectors'
  $tester.ignore_fails($nvm.pin(:fail)) do
    10.cycles
  end
  cc 'And now it should'
  $tester.cycle

  ss 'Test inhibit vectors and comments'
  cc 'The invoke pin should be driving high on this cycle'
  $nvm.pin(:invoke).drive!(1)
  cc "This should be the last thing you see until 'Inhibit complete!'"
  $tester.inhibit_vectors_and_comments do
    cc 'This should not be in the output file, or the following vectors'
    $tester.cycle
    $nvm.pin(:invoke).drive!(0)
    10.cycles
  end
  cc 'Inhibit complete!'
  cc 'The invoke pin should be driving low on this cycle'
  $tester.cycle

end
