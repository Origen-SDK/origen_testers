module OrigenTesters
  module Test
    class NVM
      attr_accessor :blocks

      include Origen::Pins
      include Origen::Registers

      def initialize
        add_reg :mclkdiv,   0x03,  16,  osch:    { pos: 15 },
                                        asel:    { pos: 14 },
                                        failctl: { pos: 13 },
                                        parsel:  { pos: 12 },
                                        eccen:   { pos: 11 },
                                        cmdloc:  { pos: 8, bits: 3, res: 0b001 },
                                        clkdiv:  { pos: 0, bits: 8, res: 0x18 }

        add_reg :data,      0x4,   16,  d: { pos: 0, bits: 16 }

        @blocks = [Block.new(0, self), Block.new(1, self), Block.new(2, self)]
      end

      def find_block_by_id(id)
        @blocks.find { |block| block.id == id }
      end

      def reg_owner_alias
        %w(flash fmu)
      end

      def override_method
        :overridden
      end

      def added_method
        :added
      end

      def add_proth_reg
        reg :proth, 0x0024, size: 32 do
          bits 31..24,   :fprot7,  reset: 0xFF
          bits 23..16,   :fprot6,  reset: 0xEE
          bits 15..8,    :fprot5,  reset: 0xDD
          bits 7..0,     :fprot4,  reset: 0x11
        end
      end
    end

    class NVMSub < NVM
      def redefine_data_reg
        add_reg :data,      0x40, 16, d: { pos: 0, bits: 16 }
      end

      # Tests that the block format for defining registers works
      def add_reg_with_block_format
        # ** Data Register 3 **
        # This is dreg
        add_reg :dreg, 0x1000, size: 16 do
          # This is dreg bit 15
          bit 15, :bit15, reset: 1
          # **Bit 14** - This does something cool
          #
          # 0 | Coolness is disabled
          # 1 | Coolness is enabled
          bits 14,    :bit14
          # This is dreg bit upper
          bits 13..8, :upper
          # This is dreg bit lower
          # This is dreg bit lower line 2
          bit 7..0,  :lower, writable: false, reset: 0x55
        end

        # This is dreg2
        reg :dreg2, 0x1000, size: 16 do
          # This is dreg2 bit 15
          bit 15,    :bit15, reset: 1
          # This is dreg2 bit upper
          bits 14..8, :upper
          # This is dreg2 bit lower
          # This is dreg2 bit lower line 2
          bit 7..0,  :lower, writable: false, reset: 0x55
        end

        # Finally a test that descriptions can be supplied via the API
        reg :dreg3, 0x1000, size: 16, description: "** Data Register 3 **\nThis is dreg3" do
          bit 15,    :bit15, reset: 1, description: 'This is dreg3 bit 15'
          bit 14, :bit14, description: "**Bit 14** - This does something cool\n\n0 | Coolness is disabled\n1 | Coolness is enabled"
          bits 13..8, :upper, description: 'This is dreg3 bit upper'
          bit 7..0, :lower, writable: false, reset: 0x55, description: "This is dreg3 bit lower\nThis is dreg3 bit lower line 2"
        end
      end
    end
  end
end
