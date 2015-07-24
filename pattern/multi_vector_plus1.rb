# This pattern is to test that patterns pad correctly when they end on an
# odd number of vectors.
# Don't add things to the main body, modify multi_vector.rb instead.

class SetupTester
  include Origen::PersistentCallbacks

  def before_pattern(pattern_name)
    case
    when pattern_name =~ /^mm_single_plus1\./
      $tester.vector_group_size = 1
    when pattern_name =~ /^mm_dual_plus1\./
      $tester.vector_group_size = 2
    when pattern_name =~ /^mm_quad_plus1\./
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
  Pattern.create(name: "mm_#{size}_plus1", skip_startup: true) do
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
    8.times do
      $dut.pin(:tclk).drive!(0)
      $dut.pin(:tclk).drive!(1)
    end
    $tester.set_timeset("nvmbist_readout", 80)
    8.times do
      $dut.pin(:tclk).drive!(0)
      $dut.pin(:tclk).drive!(1)
    end
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
    $tester.cycle

    # Don't add anything new here, the above test should be last in this pattern

  end
end
