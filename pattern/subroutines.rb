if $tester.v93k?
  tester.start_subroutine("my_sub") if tester.respond_to?(:start_subroutine)
  cc "This should be inside a subroutine pattern!"
  tester.set_timeset('tp0', 60)
  10.times do |i|
    dut.pin(:tdi).drive(i.even? ? 0 : 1)
    tester.cycle
  end
  tester.end_subroutine if tester.respond_to?(:end_subroutine)
else
  # Pattern to define subroutines
  if $tester.respond_to?('start_subroutine')
    Pattern.create(:subroutine_pat => true) do

      # Define execute subr
      $dut.execute(:define => true)

      # Define match_pin
      $dut.match(:define => true, :type => :match_pin)

      # Define match_2pins
      $dut.match(:define => true, :type => :match_2pins)

      # Define match_done subr
      $dut.match(:define => true, :type => :match_done, :delay_in_us => 5)

      # Define match_done subr with longer timeout of 7mS
      $dut.match(:subr_name => 'match_done2', :define => true, :type => :match_done, :delay_in_us => 7000)

      # Define match_done subr with longer timeout of 7sec
      $dut.match(:subr_name => 'match_done3', :define => true, :type => :match_done, :delay_in_us => 7000000)

      # Define match_done subr with longer timeout of 72sec
      $dut.match(:subr_name => 'match_done4', :define => true, :type => :match_done, :delay_in_us => 72_000_000)

      # Define match_done subr with longer timeout of 10min
      $dut.match(:subr_name => 'match_done5', :define => true, :type => :match_done, :delay_in_us => 7_000_000_000)

      # Define match loop with multiple entries
      $dut.match(:subr_name => 'match_done6', :define => true, :type => :multiple_entries, :delay_in_us => 15_000_000)

      # Define match loop with custom jump
      $dut.match(:define => true, :type => :match_2pins_custom_jump)

      # Define handshake subr
      $dut.handshake(:define => true)

      if $tester.ultraflex?
        # Define digsrc_overlay_testme32 subr
        $dut.digsrc_overlay(:subr_name => 'digsrc_overlay_testme32', :define => true, overlay_reg: :testme32)

        # Define digsrc_overlay subr
        $dut.digsrc_overlay(:subr_name => 'digsrc_overlay', :define => true, overlay_cycle_num: 64)

        # test out UF keep_alive subroutine capability
        $dut.keepalive(define: true)

        # test out single module subroutine capability, integrated with other normal subroutines
        # only for UltraFLEX
        $dut.execute(define: true, name: 'overlaysub1', onemodsub: true )
        $dut.execute(define: true, name: 'overlaysub2', onemodsub: true )
        $dut.execute(define: true, name: 'overlaysub3', onemodsub: true )
        $dut.execute(define: true, name: 'overlaysub4', onemodsub: true )
      end 
    end

    if $tester.ultraflex?
       # test out single module subroutine capability in standalone pattern
       # only for UltraFLEX
      Pattern.create(name: 'subroutines2', subroutine_pat: true) do
        $dut.execute(define: true, name: 'overlaysub5', onemodsub: true )
        $dut.execute(define: true, name: 'overlaysub6', onemodsub: true )
        $dut.execute(define: true, name: 'overlaysub7', onemodsub: true )
        $dut.execute(define: true, name: 'overlaysub4', onemodsub: true )
      end
    end
  end
end
