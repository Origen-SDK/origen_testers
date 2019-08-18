module OrigenTesters
  module Test
    class DUT
      # Simple DUT using Nexus interface

      attr_accessor :blocks
      attr_accessor :hv_supply_pin
      attr_accessor :lv_supply_pin
      attr_accessor :digsrc_pins
      attr_accessor :digcap_pins
      attr_accessor :digsrc_settings
      attr_accessor :digcap_settings
      attr_accessor :target_load_count

      include OrigenARMDebug
      include Origen::TopLevel
      include OrigenJTAG

      def initialize(options = {})
        options = {
          test_generic_overlay_capture: false
        }.merge(options)

        @test_options = {
          test_generic_overlay_capture: options[:test_generic_overlay_capture]
        }

        @target_load_count = 0

        add_pin :tclk
        add_pin :tdi
        add_pin :tdo
        add_pin :tms
        if @test_options[:test_generic_overlay_capture]
          # approved patts for this test type do not use these
          add_pin :pa0
          add_pin :pa1
          add_pin :pa2
          add_pin_group :pa, :pa2, :pa1, :pa0
          add_pin_alias :tdi_a, :tdi
        end

        if options[:extra_pins]
          options[:extra_pins].times do |i|
            add_pin "PIN_#{i}".to_sym
          end
        end
        # Add capitalized equivalent pins
        add_pin_alias :TCLK, :tclk
        add_pin_alias :TDI, :tdi
        add_pin_alias :TDO, :tdo
        add_pin_alias :TMS, :tms

        # add_pin_group :jtag, :tdi, :tdo, :tms
        add_power_pin_group :vdd1
        add_power_pin_group :vdd2
        add_virtual_pin :virtual1, type: :virtual_pin
        add_virtual_pin :virtual2, type: :ate_ch

        reg :testme32, 0x007a do |reg|
          reg.bits 31..16, :portB
          reg.bits 15..8,  :portA
          reg.bits 1,      :done
          reg.bits 0,      :enable
        end
        unless @test_options[:test_generic_overlay_capture]
          # approved patts for this test type do not use these
          @hv_supply_pin = 'VDDHV'
          @lv_supply_pin = 'VDDLV'
          @digsrc_pins = [:tdi, :tms]
          @digsrc_settings = { digsrc_mode: :parallel, digsrc_bit_order: :msb }
          @digcap_pins = :tdo
          @digcap_settings = { digcap_format: :twos_complement }
        end
        @blocks = [Block.new(0, self), Block.new(1, self), Block.new(2, self)]

        add_timeset 'tp0'
      end

      def on_create
        unless @test_options[:test_generic_overlay_capture]
          if tester && tester.uflex?
            tester.assign_dc_instr_pins([hv_supply_pin, lv_supply_pin])
            tester.assign_digsrc_pins(digsrc_pins)
            tester.apply_digsrc_settings(digsrc_settings)
            tester.assign_digcap_pins(digcap_pins)
            tester.apply_digcap_settings(digcap_settings)
            tester.memory_test_en = true
          end
        end
      end

      def on_load_target
        @target_load_count += 1
      end

      def startup(options)
        $tester.set_timeset('tp0', 60)
      end

      def write_register(reg, options = {})
        arm_debug.write_register(reg, options)
      end

      def read_register(reg, options = {})
        arm_debug.write_register(reg, options)
      end

      def execute(options = {})
        options = { define:    false,          # whether to define subr or call it
                    name:      'executefunc1',
                    onemodsub: false        # whether to expects subr to be in single module
                }.merge(options)

        if options[:define]
          # define subroutine
          $tester.start_subroutine(options[:name], onemodsub: options[:onemodsub])
          $tester.cycle
          $tester.end_subroutine(onemodsub: options[:onemodsub])
          $tester.cycle unless options[:onemodsub]
        else
          # call subroutine
          $tester.cycle
          $tester.call_subroutine(options[:name])
          $tester.cycle
        end
      end

      # Match loop functionality
      def match(options = {})
        options = { type:        :match_pin,    # whether to match DONE bit in register or match pin
                    # :match_done
                    # :match_2pins
                    delay_in_us: 5,           # match loop delay
                    define:      false,       # whether to define subr or call it
                    subr_name:   false,       # default use match type as subr name
                }.merge(options)

        subr_name = options[:subr_name] ? options[:subr_name] : options[:type].to_s

        if options[:define]
          $tester.start_subroutine(subr_name)
          $tester.cycle
          if options[:type] == :match_done

            # Match DONE bit in register
            $tester.wait(match:                 true,
                         time_in_us:            options[:delay_in_us],
                         global_loops:          true,
                         check_for_fails:       true,
                         force_fail_on_timeout: true,
                         clr_fail_post_match:   true,
                         manual_stop:           true) do
              # Match on reading done bit
              reg(:testme32).bits(:done).write(1)
              reg(:testme32).bits(:done).read!
            end
          elsif options[:type] == :match_pin
            # Match on TDO pin state
            $tester.wait(match:                 true,
                         pin:                   pin(:tdo),
                         state:                 :high,
                         time_in_us:            options[:delay_in_us],
                         global_loops:          true,
                         check_for_fails:       true,
                         force_fail_on_timeout: true,
                         clr_fail_post_match:   true,
                         manual_stop:           true)
          elsif options[:type] == :match_2pins
            # Match on TDO pin state
            $tester.wait(match:                 true,
                         pin:                   pin(:tdo),
                         state:                 :high,
                         pin2:                  pin(:tms),
                         state2:                :high,
                         time_in_us:            options[:delay_in_us],
                         global_loops:          true,
                         check_for_fails:       true,
                         force_fail_on_timeout: true,
                         clr_fail_post_match:   true,
                         manual_stop:           true)
          elsif options[:type] == :match_2pins_custom_jump
            # Match on TDO pin state
            $tester.wait(match:                 true,
                         pin:                   pin(:tdo),
                         state:                 :high,
                         pin2:                  pin(:tms),
                         state2:                :high,
                         time_in_us:            options[:delay_in_us],
                         on_pin_match_goto:     { 0 => 'no_fails_found' },
                         on_timeout_goto:       'no_fails_found',
                         global_loops:          true,
                         check_for_fails:       true,
                         force_fail_on_timeout: true,
                         clr_fail_post_match:   true,
                         manual_stop:           true)
            $tester.cycle
            $tester.set_code(200)
            $tester.branch('match_done')
            $tester.label('no_fails_found')
            $tester.set_code(201)
            $tester.label('match_done')
          elsif options[:type] == :multiple_entries
            # Match on TDO pin state, with multiple subr entry points
            $tester.wait(match:                 true,
                         pin:                   pin(:tdo),
                         state:                 :high,
                         time_in_us:            options[:delay_in_us],
                         global_loops:          true,
                         multiple_entries:      true,
                         check_for_fails:       true,
                         force_fail_on_timeout: true,
                         clr_fail_post_match:   true,
                         manual_stop:           true)
          end
          $tester.cycle
          $tester.end_subroutine
          $tester.cycle
        else
          # call subroutine
          $tester.cycle
          $tester.call_subroutine(subr_name)
          $tester.cycle
        end
      end

      def handshake(options = {})
        options = {
          define: false,          # whether to define subr or call it
        }.merge(options)

        if options[:define]
          $tester.start_subroutine('handshake')
          $tester.handshake(readcode: 100)
          $tester.cycle
          $tester.cycle
          $tester.cycle
          $tester.end_subroutine
        else
          $tester.cycle
          $tester.call_subroutine('handshake')
        end
      end

      def keepalive(options = {})
        options = {
          define:           false,          # whether to define subr or call it
          allow_subroutine: false,
          subroutine_pat:   true
        }.merge(options)

        if options[:define]
          $tester.start_subroutine('keep_alive')
          $tester.keep_alive(options)
          $tester.end_subroutine
        else
          $tester.cycle
          $tester.call_subroutine('keep_alive')
        end
      end
      alias_method :keep_alive, :keepalive

      def digsrc_overlay(options = {})
        options = { define:            false,       # whether to define subr or call it
                    subr_name:         false,       # default use match type as subr name
                    digsrc_pins:       @digsrc_pins, # defaults to what's defined in $dut
                    overlay_reg:       nil, # defaults to testme32 register
                    overlay_cycle_num: 32, # Only needed if overlay_reg is NOT nil, this specificies how many clk cycles to overlay.
                }.merge(options)
        if options[:define]
          $tester.start_subroutine(options[:subr_name]) # Start subroutine
          digsrc_pins = $tester.assign_digsrc_pins(options[:digsrc_pins])
          $tester.digsrc_start(digsrc_pins, dssc_mode: :single)
          original_pin_states = {}
          digsrc_pins.each do |pin|
            original_pin_states.merge!(pin => pin(pin).data)
            pin(pin).drive_mem
          end
          if options[:overlay_reg].nil?
            options[:overlay_cycle_num].times do
              $tester.digsrc_send(digsrc_pins)
              $tester.cycle
            end
          else
            $tester.dont_compress = true
            options[:overlay_reg].size.times do
              $tester.digsrc_send(digsrc_pins)
              $tester.cycle
            end
          end
          original_pin_states.each do |pin, state|
            pin(pin).drive(state)
          end
          $tester.digsrc_stop(digsrc_pins)
          $tester.cycle
          $tester.end_subroutine # end subroutine
        else
          $tester.cycle
          $tester.call_subroutine(options[:subr_name])
        end
      end

      def memory_test(options = {})
        options = {
        }.merge(options)

        $tester.memory_test(inc_counter_x: true, gen_vector: true)

        $tester.memory_test(inc_counter_y: true, gen_vector: true)

        $tester.memory_test(init_counter_x: true)

        $tester.memory_test(inc_counter_x: true, init_counter_y: true)

        $tester.memory_test(inc_counter_y: true, capture_vector: true)

        $tester.memory_test(pin: pin(:tdo), pin_data: :expect)
      end

      def freq_count(options = {})
        options = {
        }.merge(options)

        $tester.freq_count($dut.pin(:tdo), readcode: 73)
      end

      # dummy flag to check for a particular design bug for this DUT
      def has_margin0_bug?
        false
      end

      def find_block_by_id(id)
        @blocks.find { |block| block.id == id }
      end
    end
  end
end
