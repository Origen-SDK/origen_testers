module OrigenTesters
  module IGXLBasedTester
    class Base
      class DCSpecsets
        include ::OrigenTesters::Generator

        attr_accessor :dc_specs
        attr_accessor :dc_specsets

        OUTPUT_PREFIX = 'SpecsDC'
        # OUTPUT_POSTFIX = 'SpecsDC'

        def initialize # :nodoc:
          ## Hash Autovivification
          l = ->(h, k) { h[k] = Hash.new(&l) }

          @dc_specs = []
          @dc_specsets = Hash.new(&l)
        end

        # Assigns a DC spec value object to the given variable for this specset
        #   The attrs hash is expected to defined as follows:
        #     attrs = {
        #       specset:  :specset_name,    # if not defined, specset = :default
        #                                   # Spec selectors that contain both the scope and value of the spec
        #       nom:      { typ:  1.8 },    # typ is an example of the UFlex scope, nom is the spec selector
        #       min:      { min:  1.7 },    # Users can defined any number of selectors in this fashion
        #       max:      { max:  1.9 }
        #     }
        def add(spec, attrs = {})
          attrs = {
            specset: :default
          }.merge(attrs)

          specset = attrs.delete(:specset)

          @dc_specs << spec unless @dc_specs.include?(spec)

          attrs.each do |selector, value|
            @dc_specsets[specset][spec][selector] = value
          end
        end

        # Prepare the spec information for file output
        def format_uflex_dc_spec(data, options = {})
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
          when Integer, Float
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
      end
    end
  end
end
