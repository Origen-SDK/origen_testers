module OrigenTesters
  module Decompiler
    class Pattern
      require_relative './base'

      class Pinlist < Base
        # Returns the pinlist as an ordered list.
        # @return [Array] Array of strings where each array element is the
        #   corresponding pin in that position.
        # @example Return the pinlist.
        #   # (Teradyne ATP format) vector ($tset, tclk, tdi, tdo, tms)
        #   pinlist #=> ['tclk', 'tdi', 'tdo', 'tms']
        def pinlist
          processor.pins
        end

        def pins
          processor.pins
        end

        def processor
          @processor
        end

        def initialize(ast:, decompiled_pattern:)
          @source = :pinlist
          super
        end

        # Returns the size of the pinlist.
        # @return [Integer] Size of the pinlist.
        def pinlist_size
          processor.pinlist.size
        end

        def to_yaml_hash
          {
            class:          self.class.to_s,
            processor:      processor.class.to_s,
            pinlist:        pinlist,
            platform_nodes: _platform_nodes_
          }
        end
      end
    end
  end
end
