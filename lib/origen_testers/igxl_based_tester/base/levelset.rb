module OrigenTesters
  module IGXLBasedTester
    class Base
      class Levelset
        include ::OrigenTesters::Generator

        attr_accessor :pins
        attr_accessor :spec_category

        # Levelset name
        attr_accessor :name

        OUTPUT_PREFIX = 'LV'
        OUTPUT_POSTFIX = 'LV'

        def initialize(options = {}) # :nodoc:
          @pins = {}
        end

        # rubocop:disable Metrics/ParameterLists

        # Adds a pin level to the given levelset
        def add(lsname, pin, level, options = {})
          options = {
            spec_category: 'default'  # defines which specset category to put variables in (e.g. func, scan) when generating specset files
          }.merge(options)
          lsname = lsname.to_sym unless lsname.is_a? Symbol
          pin = pin.to_sym unless pin.is_a? Symbol

          add_level(pin, level)
          @name = lsname
          @spec_category = options[:spec_category]
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
          if Origen.top_level.pin(grp).is_a?(Origen::Pins::FunctionProxy)
            pins << Origen.top_level.pin(grp)
          elsif Origen.top_level.pin(grp).is_a?(Origen::Pins::PinCollection)
            Origen.top_level.pin(grp).each do |pin|
              pins << pin
            end
          end
          pins
        end

        # Equality check to compare full contents of 2 level objects
        def levels_eql?(level1, level2)
          # determine if object is a power level (conatins :vmain) or a SE pin level (:vil)
          if level1.respond_to?(:vmain) && level2.respond_to?(:vmain)
            level1.vmain == level2.vmain && level1.valt == level2.valt && level1.ifold == level2.ifold && level1.delay == level2.delay
          elsif level1.respond_to?(:vil) && level2.respond_to?(:vil)
            level1.vil == level2.vil && level1.vih == level2.vih && level1.vol == level2.vol && level1.voh == level2.voh && level1.vcl == level2.vcl && level1.vch == level2.vch && level1.vt == level2.vt && level1.voutlotyp == level2.voutlotyp &&
              level1.vouthityp == level2.vouthityp &&
              level1.dmode == level2.dmode
          else
            false
          end
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
          options = {
          }.merge(options)

          if data !~ /^\s*$/
            data = data.gsub(/^/, '=')
          end
          data = data.gsub(/(\W)([a-zA-Z])/, '\1_\2')
          data = data.gsub(/(\*\s*)_([kmun]{0,1}[AVs]{1})/, '\1\2')
        end

        # Prepare the spec information for file output
        def format_uflex_level(data, options = {})
          options = {
            spec: nil
          }.update(options)

          case options[:spec]
          when /(voh|vol|vt|vcl|vch|vdd)/i
            spec_type = 'volt'
          when /(ioh|iol)/i
            spec_type = 'curr'
          else
            spec_type = nil
          end

          case data
          when NilClass
            data_new = 0
          when Fixnum, Float
            case
            when data == 0
              data_new = data.to_s
            when data.abs < 1e-6
              data_new = (data * 1_000_000_000).round(4).to_s + '*nV' if spec_type == 'volt'
              data_new = (data * 1_000_000_000).round(4).to_s + '*nA' if spec_type == 'curr'
              data_new = data.to_s if spec_type.nil?
            when data.abs < 1e-3
              data_new = (data * 1_000_000).round(4).to_s + '*uV' if spec_type == 'volt'
              data_new = (data * 1_000_000).round(4).to_s + '*uA' if spec_type == 'curr'
              data_new = data.to_s if spec_type.nil?
            when data.abs < 1
              data_new = data.to_s + '*V' if spec_type == 'volt'
              data_new = (data * 1_000).round(4).to_s + '*mA' if spec_type == 'curr'
              data_new = data.to_s if spec_type.nil?
            else
              data_new = data.to_s + '*V' if spec_type == 'volt'
              data_new = data.to_s + '*A' if spec_type == 'curr'
              data_new = data.to_s if spec_type.nil?
            end
            data_new = data_new.gsub(/^/, '=')
          when String
            data_new = data.gsub(/^/, '=').gsub(/(\W)([a-zA-Z])/, '\1_\2')
            # Remove underscores from unit designations
            data_new.gsub!(/(\W)_(nV|uV|mV|V|nA|uA|mA|A)(\W)/i, '\1\2\3')
            data_new.gsub!(/(\W)_(nV|uV|mV|V|nA|uA|mA|A)$/i, '\1\2')
          else
            Origen.log.error "Unknown class type (#{data.class}) for spec value:  #{data}"
            fail
          end
          data_new
        end

        def platform
          Origen.interface.platform
        end
      end
    end
  end
end
