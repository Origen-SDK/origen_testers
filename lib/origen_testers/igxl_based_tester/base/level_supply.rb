module OrigenTesters
  module IGXLBasedTester
    class Base
      class SupplyLevel
        attr_accessor :vmain, :valt     # Supply level information
        attr_accessor :ifold            # Clamp current information
        attr_accessor :delay            # Supply power-up delay

        def initialize(options = {}) # :nodoc:
          options = {
            vmain: 1.8,                # Main supply voltage
            valt:  1.8,                # Alternate supply voltage
            ifold: 1,                # Supply clamp current
            delay: 0                 # Supply power-up delay
          }.merge(options)
          @vmain = options[:vmain]
          @valt  = options[:valt]
          @ifold = options[:ifold]
          @delay = options[:delay]
        end

        def ==(level)
          if level.is_a? PinLevelSingle
            vmain == level.vmain &&
            valt == level.valt &&
            ifold == level.ifold &&
            delay == level.delay
          else
            super
          end
        end

        def platform
          Origen.interface.platform
        end
      end
    end
  end
end
