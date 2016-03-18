module OrigenTesters
  module IGXLBasedTester
    class Base
      class ACSpecsets
        include ::OrigenTesters::Generator

        attr_accessor :ac_specs
        attr_accessor :ac_specsets

        OUTPUT_PREFIX = 'SpecsAC'
        # OUTPUT_POSTFIX = 'SpecsAC'

        def initialize # :nodoc:
          ## Hash Autovivification
          l = ->(h, k) { h[k] = Hash.new(&l) }

          @ac_specs = []
          @ac_specsets = Hash.new(&l)
        end

        # Assigns an AC spec value object to the given variable for this specset
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

          @ac_specs << spec unless @ac_specs.include?(spec)

          attrs.each do |selector, value|
            @ac_specsets[specset][spec][selector] = value
          end
        end

        # Prepare the spec information for file output
        def format_uflex_ac_spec(data, options = {})
          case data
          when NilClass
            data_new = 0
          when Fixnum, Float
            case
            when data == 0
              data_new = data.to_s
            when data.abs < 1e-9
              data_new = (data * 1_000_000_000_000).round(4).to_s + '*ps'
            when data.abs < 1e-6
              data_new = (data * 1_000_000_000).round(4).to_s + '*ns'
            when data.abs < 1e-3
              data_new = (data * 1_000_000).round(4).to_s + '*us'
            when data.abs < 1
              data_new = (data * 1_000).round(4).to_s + '*ms'
            else
              data_new = data.to_s
            end
            data_new = data_new.gsub(/^/, '=')
          when String
            data_new = data.gsub(/^/, '=').gsub(/(\W)([a-zA-Z])/, '\1_\2')
            # Remove underscores from unit designations
            data_new.gsub!(/(\W)_(nS|uS|mS|S)(\W)/i, '\1\2\3')
            data_new.gsub!(/(\W)_(nS|uS|mS|S)$/i, '\1\2')
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
