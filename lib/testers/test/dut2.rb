module Testers
  module Test
    class DUT2
      include RGen::TopLevel

      def initialize
        add_pin :reset,   reset: :drive_hi,  name: 'nvm_reset'
        add_pin :clk,     reset: :drive_hi,  name: 'nvm_clk'
        add_pin :clk_mux, reset: :drive_hi,  name: 'nvm_clk_mux'
        add_port :porta,   reset: :drive_lo,  size: 8
        add_port :portb,   reset: :drive_lo,  size: 8, endian: :little
        add_pin :invoke,  reset: :drive_lo,  name: 'nvm_invoke'
        add_pin :done,    reset: :expect_hi, name: 'nvm_done'
        add_pin :fail,    reset: :expect_lo, name: 'nvm_fail'
        add_pin :alvtst,  reset: :dont_care, name: 'nvm_alvtst'
        add_pin :ahvtst,  reset: :dont_care, name: 'nvm_ahvtst'
        add_pin :dtst,    reset: :dont_care, name: 'nvm_dtst'

        add_pin :tclk, reset: :drive_lo
        add_pin :trst, reset: :drive_hi

        add_pin_alias :extal,     :clk
        add_pin_alias :extal_mux, :clk_mux
        add_pin_alias :tms,       :done
        add_pin_alias :tdo,       :fail
        add_pin_alias :tdi,       :invoke
        add_pin_alias :resetb,    :ahvtst

        add_pin_alias :pa5, :porta, pin: 5
        add_pin_alias :pa_lower, :porta, pins: [3..0]
        add_pin_alias :pa_upper, :porta, pins: [7, 6, 5, 4]
        add_port_alias :porta_alias, :porta
      end

      def startup(options)
        if options[:add_additional_pins]
          add_pin :late_added_pin, reset: :drive_hi
        else
          # Test that rendering some vectors from a template works...
          if $tester.is_a?(J750)
            $tester.render("#{RGen.root}/pattern/nvm/j750/_mode_entry.atp.erb", hold_cycles: 5)
          end
        end
        $tester.set_timeset('nvmbist', 40) if $tester.is_vector_based?
      end

      def has_margin0_bug?
        false
      end

      def write_register(reg, options = {})
        reg
      end

      def read_register(reg, options = {})
        reg
      end

      def base_address(reg, options = {})
        if reg.owned_by?(:nvm)
          0x4000_0000
        else
          0
        end
      end

      def rgen_dot_root
        RGen.root
      end

      def rgen_dot_root!
        RGen.root!
      end
    end
  end
end
