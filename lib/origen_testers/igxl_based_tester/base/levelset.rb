module OrigenTesters
  module IGXLBasedTester
    class Base
      class Levelset
        include ::OrigenTesters::Generator

        attr_accessor :pins
        attr_accessor :spec_sheet
        attr_accessor :ls_sheet_pins

        # Levelset name
        attr_accessor :name

        OUTPUT_PREFIX = 'LV'
        # OUTPUT_POSTFIX = 'LV'

        def initialize(options = {}) # :nodoc:
          @pins = {}
        end

        # Adds a pin level to the given levelset
        def add(lsname, pin, level, options = {})
          options = {
            spec_sheet: 'default'  # defines which specset sheet to put variables in (e.g. func, scan) when generating specset files
          }.merge(options)
          lsname = lsname.to_sym unless lsname.is_a? Symbol
          pin = pin.to_sym unless pin.is_a? Symbol

          add_level(pin, level)
          @name = lsname
          @spec_sheet = options[:spec_sheet]
          @ls_sheet_pins ||= options[:ls_sheet_pins]
        end

        # Assigns a level object to the given pin for this levelset
        def add_level(pin, level)
          if @pins.key?(pin)
            Origen.log.error "Pin #{pin} already exists in levelset"
          else
            @pins[pin] = level
          end
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

        # Equality check to compare full contents of 2 level objects
        def levels_eql?(level1, level2)
          level1 == level2
        end

        # Globally modify text within the level object
        def gsub_levels!(level, old_val, new_val)
          # determine if object is a power level (conatins :vmain) or a SE pin level (:vil)
          if level.respond_to?(:vmain)
            level.vmain     = level.vmain.gsub(/#{Regexp.escape(old_val)}/, new_val)
            level.valt      = level.valt.gsub(/#{Regexp.escape(old_val)}/, new_val)
            level.ifold     = level.ifold.gsub(/#{Regexp.escape(old_val)}/, new_val)
            # level.delay     = level.delay.gsub(/#{Regexp.escape(old_val)}/, new_val)
          elsif level.respond_to?(:vil)
            level.vil       = level.vil.gsub(/#{Regexp.escape(old_val)}/, new_val)
            level.vih       = level.vih.gsub(/#{Regexp.escape(old_val)}/, new_val)
            level.vol       = level.vol.gsub(/#{Regexp.escape(old_val)}/, new_val)
            level.voh       = level.voh.gsub(/#{Regexp.escape(old_val)}/, new_val)
            level.vcl       = level.vcl.gsub(/#{Regexp.escape(old_val)}/, new_val)
            level.vch       = level.vch.gsub(/#{Regexp.escape(old_val)}/, new_val)
            level.vt        = level.vt.gsub(/#{Regexp.escape(old_val)}/, new_val)
            level.voutlotyp = level.voutlotyp.gsub(/#{Regexp.escape(old_val)}/, new_val)
            level.vouthityp = level.vouthityp.gsub(/#{Regexp.escape(old_val)}/, new_val)
            level.dmode     = level.dmode.gsub(/#{Regexp.escape(old_val)}/, new_val)
          end
        end

        def format_uflex_level(data, options = {})
          options = {}.merge(options)

          if data !~ /^\s*$/
            data = data.gsub(/^/, '=')
          end
          data = data.gsub(/(\W)([a-zA-Z])/, '\1_\2')
          data = data.gsub(/(\*\s*)_([kmun]{0,1}[AVs]{1}\W)/, '\1\2')
          data = data.gsub(/(\*\s*)_([kmun]{0,1}[AVs]{1})$/, '\1\2')
        end

        def platform
          Origen.interface.platform
        end
      end
    end
  end
end
