module OrigenTesters
  module IGXLBasedTester
    class Base
      class PinLevelSingle
        attr_accessor :vil, :vih        # Input level information
        attr_accessor :vol, :voh        # Output level information
        attr_accessor :vcl, :vch        # Clamp level information
        attr_accessor :vt               # Termination level information
        attr_accessor :voutlotyp, :vouthityp, :dmode

        def initialize(options = {}) # :nodoc:
          options = {
            vil:       0,            # Input drive low
            vih:       1.8,            # Input drive high
            vol:       1.0,            # Output compare low
            voh:       0.8,            # Output compare high
            vcl:       -1,            # Voltage clamp low
            vch:       2.5,            # Voltage clamp high
            vt:        0.9,            # Termination voltage
            voutlotyp: 0,
            vouthityp: 0,
            dmode:     'Largeswing-VT' # Driver mode (possibly ATE-specific)
          }.merge(options)
          @vil       = options[:vil]
          @vih       = options[:vih]
          @vol       = options[:vol]
          @voh       = options[:voh]
          @vcl       = options[:vcl]
          @vch       = options[:vch]
          @vt        = options[:vt]
          @voutlotyp = options[:voutlotyp]
          @vouthityp = options[:vouthityp]
          @dmode     = options[:dmode]
        end

        def ==(level)
          if level.is_a? PinLevelSingle
            vil == level.vil &&
              vih == level.vih &&
              vol == level.vol &&
              voh == level.voh &&
              vcl == level.vcl &&
              vch == level.vch &&
              vt == level.vt &&
              voutlotyp == level.voutlotyp &&
              vouthityp == level.vouthityp &&
              dmode == level.dmode
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
