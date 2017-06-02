module OrigenTesters
  class MemoryStyle
    # TODO: it doesn't seem likely that this will work well if a mix of base
    # pin names and aliased (or grouped) pin names are used to refer to the
    # same pin for multiple configuration settings.  Should update this code
    # to always resolve the pin_id to it's base name.

    attr_reader :pin_id, :size, :bit_order, :format, :trigger

    def initialize
      @pin_id = []
      @size = []
      @bit_order = []
      @format = []
      @trigger = []
    end

    # Set memory style attributes for the given pin
    #
    # @example
    #   mem.pin :tdi, size: 8, trigger: :auto
    def pin(*pin_ids)
      options = pin_ids.last.is_a?(Hash) ? pin_ids.pop : {}
      @pin_id << pin_ids
      @size << options[:size]
      @bit_order << options[:bit_order]
      @format << options[:format]
      @trigger << options[:trigger]
    end

    # Get the chronologically last setting for the given pin's attributes
    #
    # @example
    #   mem.pin :tdi, size: 1
    #   mem.pin :tdi, size: 2
    #
    #   my_local_attribute_hash = mem.accumulate_attributes(:tdi)
    #   # my_local_attribute_hash now is
    #   # {pin_id: :tdi, size: 2, bit_order: nil, format: nil, trigger: nil}
    def accumulate_attributes(pin_id)
      a = { pin_id: pin_id }
      @pin_id.each_index do |i|
        if @pin_id[i].include?(pin_id)
          a[:size] = @size[i]
          a[:bit_order] = @bit_order[i]
          a[:format] = @format[i]
          a[:trigger] = @trigger[i]
        end
      end
      a
    end

    # Check to see if a given pin exists in this style container
    def contains_pin?(pin_id)
      contained_pins.include?(pin_id)
    end

    # Get an array of pins contained in this style container
    def contained_pins
      pins = []
      @pin_id.each do |a|
        a.each do |p|
          pins << p
        end
      end
      pins.uniq
    end
  end
end
