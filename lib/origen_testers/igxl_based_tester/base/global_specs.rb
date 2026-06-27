module OrigenTesters
  module IGXLBasedTester
    class Base
      class GlobalSpecs
        include ::OrigenTesters::Generator

        attr_accessor :global_specs

        OUTPUT_PREFIX = 'SpecsGlobal'
        # OUTPUT_POSTFIX = 'SpecsGlobal'

        def initialize # :nodoc:
          ## Hash Autovivification
          l = ->(h, k) { h[k] = Hash.new(&l) }
          @global_specs = Hash.new(&l)
        end

        # Assigns a global spec value object to the given variable
        #   The attrs hash is expected to defined as follows:
        #     attrs = {
        #       job:    nil,
        #       value:  0
        #     }
        def add(spec, attrs = {})
          attrs = {
            job:   :nil,
            value: 0
          }.merge(attrs)

          @global_specs[spec][attrs.delete(:job)] = attrs
        end

        # Prepare the spec information for file output
        def format_uflex_global_spec(data, options = {})
          options = {
            spec: nil
          }.update(options)

          case options[:spec]
          when /fgb_/i
            spec_type = 'freq'
          when /vgb_/i
            spec_type = 'volt'
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
              data_new = data.to_s if spec_type.nil?
            when data.abs < 1e-3
              data_new = (data * 1_000_000).round(4).to_s + '*uV' if spec_type == 'volt'
              data_new = data.to_s if spec_type.nil?
            when data.abs < 1
              data_new = (data * 1_000).round(4).to_s + '*mV' if spec_type == 'volt'
              data_new = data.to_s if spec_type.nil?
            else
              data_new = data.to_s + '*V' if spec_type == 'volt'
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
