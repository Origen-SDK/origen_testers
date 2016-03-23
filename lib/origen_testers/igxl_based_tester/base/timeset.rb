module OrigenTesters
  module IGXLBasedTester
    class Base
      class Timeset
        attr_accessor :master_ts, :t_mode  # Timeset information
        attr_accessor :pins
        attr_accessor :name

        # Specify timeset information by providing a pin and its associated edge timing
        def initialize(name, pin, edge, attrs = {}) # :nodoc:
          attrs = {
            master_ts: '', # master timeset name
            t_mode:    ''  # timing mode (possibly ATE-specific)
          }.merge(attrs)
          @master_ts = attrs[:master_ts]
          @t_mode    = attrs[:t_mode]
          @pins      = { pin => edge }
          self.name = name
        end

        # Assigns a timing edge object to the given pin for this timeset
        def add_edge(pin, edge)
          if @pins.key?(pin)
            Origen.log.error "Pin #{pin} already exists in timeset"
            fail
          else
            @pins[pin] = edge
          end
        end

        def platform
          Origen.interface.platform
        end
      end
    end
  end
end
