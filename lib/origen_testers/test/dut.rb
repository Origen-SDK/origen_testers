module OrigenTesters
  module Test
    class DUT
      # Simple DUT using Nexus interface

      attr_accessor :blocks
      attr_accessor :hv_supply_pin
      attr_accessor :lv_supply_pin

      include OrigenARMDebug
      include Origen::TopLevel
      include OrigenJTAG

      def initialize(options = {})
        add_pin :tclk
        add_pin :tdi
        add_pin :tdo
        add_pin :tms

        add_reg32 :testme32, 0x007a do
          bits 31..16, :portB
          bits 15..8,  :portA
          bits 1,      :done
          bits 0,      :enable
        end
        @hv_supply_pin = 'VDDHV'
        @lv_supply_pin = 'VDDLV'
        @blocks = [Block.new(0, self), Block.new(1, self), Block.new(2, self)]
      end

      def startup(options)
        $tester.set_timeset('tp0', 60)
      end

      def write_register(reg, options={})
        arm_debug.write_register(reg, options)
      end

      def read_register(reg, options={})
        arm_debug.write_register(reg, options)
      end

      def execute(options = {})
        options = { define: false,          # whether to define subr or call it
                    name:   'executefunc1'
                }.merge(options)

        if options[:define]
          # define subroutine
          $tester.start_subroutine(options[:name])
          $tester.cycle
          $tester.end_subroutine
          $tester.cycle
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
