module OrigenTesters
  module IGXLBasedTester
    class Base
      class Edgeset
        attr_accessor :period, :t_mode  # Edgeset information
        attr_accessor :pins
        attr_accessor :spec_sheet
        attr_accessor :name

        def initialize(name, pin, edge, attrs = {}) # :nodoc:
          attrs = {
            period:     '',        # tester cycle duration
            t_mode:     '',        # timing mode (possibly ATE-specific)
            spec_sheet: 'default'  # defines which specset sheet to put variables in (e.g. func, scan) when generating specset files
          }.merge(attrs)
          @period     = attrs[:period]
          @t_mode     = attrs[:t_mode]
          @spec_sheet = attrs[:spec_sheet]
          @pins       = { pin => edge }
          self.name = name
        end

        # Assigns a timing edge object to the given pin for this edgeset
        def add_edge(pin, edge)
          if @pins.key?(pin)
            Origen.log.error "Pin #{pin} already exists in edgeset"
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
