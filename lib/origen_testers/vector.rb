module OrigenTesters
  # A simple class to model a vector
  class Vector
    attr_accessor :repeat, :microcode, :timeset, :pin_vals,
                  :number, :cycle_number, :dont_compress,
                  :comments, :inline_comment, :cycle, :number

    def initialize(attrs = {})
      @inline_comment = ''
      attrs.each do |attribute, value|
        send("#{attribute}=", value)
      end
    end

    def comments
      @comments ||= []
    end

    def update(attrs = {})
      attrs.each do |attribute, value|
        send("#{attribute}=", value)
      end
    end

    # Returns the value (a string) that is assigned to the given pin by the
    # given vector
    #
    #   vector.pin_vals                     # => "1 1 XX10 H X1"
    #   vector.pin_value($dut.pins(:jtag))  # => "XX10"
    def pin_value(pin)
      $tester.regex_for_pin(pin).match(pin_vals)
      Regexp.last_match(1)
    end

    # Replace the current pin value assigned to the given pin with either the state
    # that it currently has, or with a supplied string value.
    #
    # In the case of a string being supplied as the 2nd argument, the caller is
    # responsible for ensuring that the pin state format/codes matches that used
    # by the current tester.
    #
    #   vector.pin_vals                          # => "1 1 XX10 H X1"
    #   $dut.pins(:jtag).drive(0)
    #   vector.set_pin_value($dut.pins(:jtag))
    #   vector.pin_vals                          # => "1 1 0000 H X1"
    #   vector.set_pin_value($dut.pins(:jtag), "XXXX")
    #   vector.pin_vals                          # => "1 1 XXXX H X1"
    def set_pin_value(pin, value = nil)
      regex = $tester.regex_for_pin_sub(pin)
      value ||= pin.to_vector
      if $tester.ordered_pins_cache.first == pin
        self.pin_vals = pin_vals.sub(regex, value + '\2')
      elsif $tester.ordered_pins_cache.last == pin
        self.pin_vals = pin_vals.sub(regex, '\1' + value)
      else
        self.pin_vals = pin_vals.sub(regex, '\1' + value + '\3')
      end
    end

    # Converts the vector to the period specified by the given timeset (instead of the period
    # for the timeset it was originally created with).
    #
    # This may convert the single vector to multiple vectors, in which case the method will
    # yield as many vectors as required back to the caller.
    def convert_to_timeset(tset)
      # If no conversion required
      if tset.period_in_ns == timeset.period_in_ns
        yield self
      else
        if tset.period_in_ns > timeset.period_in_ns
          fail "Cannot convert a vector with timeset #{timeset.name} to timeset #{tset.name}!"
        end
        if timeset.period_in_ns % tset.period_in_ns != 0
          fail "The period of timeset #{timeset.name} is not a multiple of the period of timeset #{tset.name}!"
        end
        if $tester.timing_toggled_pins.empty?
          vector_modification_required = false
        else
          # If the timing toggled pins are not driving on this vector, then no
          # modification will be required
          vector_modification_required = $tester.timing_toggled_pins.any? do |pin|
            value = pin_value(pin)
            value == '1' || value == '0'
          end
        end
        number_of_base_vectors = repeat || 1
        vectors_per_period = timeset.period_in_ns / tset.period_in_ns
        self.inline_comment += "Period levelled (#{timeset.name})"
        self.timeset = tset
        if vector_modification_required && vectors_per_period > 1
          pin_values = $tester.timing_toggled_pins.map do |pin|
            on = pin_value(pin)
            if on == '1'
              { pin: pin, on: '1', off: '0' }
            elsif on == '0'
              { pin: pin, on: '0', off: '1' }
            end
          end
          pin_vals_with_compare = nil
          number_of_base_vectors.times do |i|
            # Drive the 'on' value on the first cycle, this is already setup
            v = dup
            v.repeat = 1
            v.pin_vals = inhibit_compares
            yield v
            # Then drive the pin 'off' value for the remainder
            v = dup
            r = vectors_per_period - 1
            if r > 1
              v = dup
              v.repeat = r - 1
              pin_values.each { |vals| v.set_pin_value(vals[:pin], vals[:off]) if vals }
              yield v
            end
            v = dup
            v.repeat = 1
            v.pin_vals = restore_compares
            pin_values.each { |vals| v.set_pin_value(vals[:pin], vals[:off]) if vals }
            yield v
          end
        else
          self.repeat = number_of_base_vectors * vectors_per_period
          yield self
        end
      end
    end

    # Set all active compare data to X.
    # The original values will be preserved so that they can be restored
    #   vector.pin_vals            # => "1 1 LHLL 10001 L 1 XX 0"
    #   vector.inhibit_compares    # => "1 1 XXXX 10001 X 1 XX 0"
    #   vector.restore_compares    # => "1 1 LHLL 10001 L 1 XX 0"
    def inhibit_compares
      @orig_pin_vals = pin_vals
      @pin_vals = pin_vals.gsub(/H|L/, 'X')
    end

    # @see Vector#inhibit_compares
    def restore_compares
      @pin_vals = @orig_pin_vals
    end

    # Updates the pin values to reflect the value currently held by the given pin
    def update_pin_val(pin)
      vals = pin_vals.split(' ')
      if pin.belongs_to_a_pin_group? && !pin.is_a?(Origen::Pins::PinCollection)
        port = nil
        pin.groups.each { |i| port = i[1] if port.nil? && Origen.tester.ordered_pins.include?(i[1]) } # see if group is included in ordered pins
        if port
          ix = Origen.tester.ordered_pins.index(port) # find index of port
          i = port.find_index(pin)
        elsif
          ix = Origen.tester.ordered_pins.index(pin)
          i = 0
        end
      else
        ix = Origen.tester.ordered_pins.index(pin)
        i = 0
      end

      if Origen.pin_bank.pin_groups.keys.include? pin.id
        val = pin.map { |p| Origen.tester.format_pin_state(p) }.join('')
        vals[ix] = val
      else
        val = Origen.tester.format_pin_state(pin)
        vals[ix][i] = val
      end

      self.pin_vals = vals.join(' ')
    end

    def ordered_pins
      Origen.app.pin_map.sort_by { |id, pin| pin.order }.map { |id, pin| pin }
    end

    def microcode=(val)
      if val && has_microcode? && @microcode != val
        fail "Trying to assign microcode: #{val}, but vector already has microcode: #{@microcode}"
      else
        @microcode = val
      end
    end

    # Since repeat 0 is non-intuitive every vector implicitly has a repeat of 1
    def repeat
      @repeat || 1
    end

    def has_microcode?
      !!(@microcode && !@microcode.empty?)
    end

    def ==(obj)
      if obj.is_a?(Vector)
        self.has_microcode? == obj.has_microcode? &&
          timeset == obj.timeset &&
          pin_vals == obj.pin_vals
      else
        super obj
      end
    end
  end
end
