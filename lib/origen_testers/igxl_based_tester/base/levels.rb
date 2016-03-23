module OrigenTesters
  module IGXLBasedTester
    class Base
      class Levels
        include ::OrigenTesters::Generator

        # If levels are defined for a power group then this will return the level object
        attr_accessor :pwr_group
        # If levels are defined for a pin group then this will return the level object
        attr_accessor :pin_group

        def initialize(options = {}) # :nodoc:
          @pwr_group = Hash.new { |h, k| h[k] = {} }
          @pin_group = Hash.new { |h, k| h[k] = {} }
        end

        # Defines a new Power Level category for the given pin/group
        def add_power_level(cat, options = {})
          cat = cat.to_sym unless cat.is_a? Symbol
          pwr_group[cat] = platform::SupplyLevel.new(options)
        end

        # Defines a new Single-Ended Pin Level category for the given pin/group
        def add_se_pin_level(cat, options = {})
          cat = cat.to_sym unless cat.is_a? Symbol
          pin_group[cat] = platform::PinLevelSingle.new(options)
        end
      end
    end
  end
end
