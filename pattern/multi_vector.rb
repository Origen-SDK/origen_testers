class SetupTester
  include Origen::PersistentCallbacks

  def before_pattern(pattern_name)
    case
    when pattern_name =~ /^mm_single\./
      $tester.vector_group_size = 1
    when pattern_name =~ /^mm_dual\./
      $tester.vector_group_size = 2
    when pattern_name =~ /^mm_quad\./
      $tester.vector_group_size = 4
    else
      # To avoid breaking later tests
      $tester.vector_group_size = 1
    end
  end
end
SetupTester.new

[:single, :dual, :quad].each do |size|
  # Startup is being skipped here since it is currently a test of the ability
  # to render (i.e. paste) vectors, therefore they are not compressible by
  # Origen and which makes debugging this confusing!
  Pattern.create(name: "mm_#{size}", skip_startup: true) do
    $tester.set_timeset("nvmbist", 40)

    ss "$tester.cycle(repeat: 128)"
    $tester.cycle(repeat: 128)

    ss do
      cc "64.times do"
      cc "  $dut.pin(:tclk).drive!(0)"
      cc "  $dut.pin(:tclk).drive!(1)"
      cc "end"
    end
    64.times do
      $dut.pin(:tclk).drive!(0)
      $dut.pin(:tclk).drive!(1)
    end

    ss do
      cc "64.times do"
      cc "  $dut.pin(:tclk).drive!(0)"
      cc "  $dut.pin(:tclk).drive!(0)"
      cc "  $dut.pin(:tclk).drive!(1)"
      cc "  $dut.pin(:tclk).drive!(1)"
      cc "end"
    end
    64.times do
      $dut.pin(:tclk).drive!(0)
      $dut.pin(:tclk).drive!(0)
      $dut.pin(:tclk).drive!(1)
      $dut.pin(:tclk).drive!(1)
    end

    ss do
      cc "64.times do"
      cc "  $dut.pin(:tclk).drive!(0)"
      cc "  $dut.pin(:tclk).drive!(0)"
      cc "  $dut.pin(:tclk).drive!(0)"
      cc "  $dut.pin(:tclk).drive!(0)"
      cc "  $dut.pin(:tclk).drive!(1)"
      cc "  $dut.pin(:tclk).drive!(1)"
      cc "  $dut.pin(:tclk).drive!(1)"
      cc "  $dut.pin(:tclk).drive!(1)"
      cc "end"
    end
    64.times do
      $dut.pin(:tclk).drive!(0)
      $dut.pin(:tclk).drive!(0)
      $dut.pin(:tclk).drive!(0)
      $dut.pin(:tclk).drive!(0)
      $dut.pin(:tclk).drive!(1)
      $dut.pin(:tclk).drive!(1)
      $dut.pin(:tclk).drive!(1)
      $dut.pin(:tclk).drive!(1)
    end

    ss do
      cc "Test of period levelling"
    end
    $tester.timing_toggled_pins << $dut.pin(:tclk)
    $dut.pin(:tdo).assert(0)
    8.cycles
    $tester.set_timeset("nvmbist_readout", 160)
    8.cycles
    $dut.pin(:tdo).dont_care
    $tester.set_timeset("nvmbist", 40)

    if $tester.vector_group_size == 1
      ss do
        cc "Test that these collapse to a single repeat in the single vector case"
      end
      $dut.pin(:tdi).drive(1)
      $tester.wait cycles: 60000
      $tester.cycle
      $dut.pin(:tdi).dont_care
    end

    ss do
      cc "Test that these collapse to correct multiple repeats"
    end
    $dut.pin(:tdi).drive(1)
    $tester.wait cycles: 300000
    $dut.pin(:tdi).dont_care

    ss do
      cc "Verify that comments at the end of the pattern work OK"
    end
    $dut.pin(:tdi).drive(0)
    $tester.wait cycles: 1200
    cc "This comment should appear after the delay 1200"

    # Don't add anything new here, the above test should be last in this pattern

  end
end
