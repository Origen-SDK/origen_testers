module OrigenTesters
  module IGXLBasedTester
    class Base
      class Timesets
        include ::OrigenTesters::Generator

        attr_accessor :ts
        attr_accessor :ts_sheet_pins

        OUTPUT_PREFIX = 'TS'
        # OUTPUT_POSTFIX = 'TS'

        def initialize # :nodoc:
          @ts = {}
        end

        def add(tsname, pin, esname, options = {})
          tsname = tsname.to_sym unless tsname.is_a? Symbol
          pin = pin.to_sym unless pin.is_a? Symbol
          esname = pin.to_sym unless esname.is_a? Symbol
          @ts.key?(tsname) ? @ts[tsname].add_edge(pin, esname) : @ts[tsname] = platform::Timeset.new(tsname, pin, esname, options)
          @ts_sheet_pins = options[:ts_sheet_pins] unless @ts_sheet_pins
          @ts[tsname]
        end

        def finalize(options = {})
        end

        # Populate an array of pins based on the pin or pingroup
        def get_pin_objects(grp)
          pins = []
          if Origen.top_level.pin(grp).is_a?(Origen::Pins::Pin) ||
            Origen.top_level.pin(grp).is_a?(Origen::Pins::FunctionProxy)
            pins << Origen.top_level.pin(grp)
          elsif Origen.top_level.pin(grp).is_a?(Origen::Pins::PinCollection)
            Origen.top_level.pin(grp).each do |pin|
              pins << pin
            end
          else
            Origen.log.error "Could not find pin class: #{grp}  #{Origen.top_level.pin(grp).class}"
          end
          pins
        end
      end
    end
  end
end
