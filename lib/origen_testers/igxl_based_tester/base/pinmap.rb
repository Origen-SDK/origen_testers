module OrigenTesters
  module IGXLBasedTester
    class Base
      class Pinmap
        include ::OrigenTesters::Generator

        attr_accessor :pins
        attr_accessor :pin_groups
        attr_accessor :power_pins
        attr_accessor :utility_pins

        PIN_TYPES = ['I/O', 'I', 'O']
        PWR_TYPES = ['Power']
        UTL_TYPES = ['Utility', 'I/O', 'I', 'O']

        def initialize # :nodoc:
          @pins = {}
          @pin_groups = Hash.new { |h, k| h[k] = {} }
          @power_pins = {}
          @utility_pins = {}
        end

        def add_pin(pin_name, attrs = {})
          attrs = {
            type:    'I/O',
            comment: ''
          }.merge(attrs)
          pin_name = pin_name.to_sym unless pin_name.is_a? Symbol
          if PIN_TYPES.include? attrs[:type]
            type = attrs[:type]
          else
            Origen.log.error "Pinmap individual pin type '#{attrs[:type]}' must be set to one of the following: #{PIN_TYPES.join(', ')} for pin '#{pin_name}'"
            fail
          end
          @pins[pin_name] = { type: type, comment: attrs[:comment] }
        end

        def add_group_pin(grp_name, pin_name, attrs = {})
          attrs = {
            type:    'I/O',
            comment: ''
          }.merge(attrs)
          grp_name = grp_name.to_sym unless grp_name.is_a? Symbol
          pin_name = pin_name.to_sym unless pin_name.is_a? Symbol
          if PIN_TYPES.include? attrs[:type]
            type = attrs[:type]
          else
            Origen.log.error "Pinmap group pin type '#{attrs[:type]}' must be set to one of the following: #{PIN_TYPES.join(', ')} for pin '#{pin_name}'"
            fail
          end
          @pin_groups[grp_name][pin_name] = { type: attrs[:type], comment: attrs[:comment] }
        end

        def add_power_pin(pin_name, attrs = {})
          attrs = {
            type:    'Power',
            comment: ''
          }.merge(attrs)
          pin_name = pin_name.to_sym unless pin_name.is_a? Symbol
          if PWR_TYPES.include? attrs[:type]
            type = attrs[:type]
          else
            Origen.log.error "Pinmap powerpin type '#{attrs[:type]}' must be set to one of the following: #{PWR_TYPES.join(', ')} for pin '#{pin_name}'"
            fail
          end
          @power_pins[pin_name] = { type: attrs[:type], comment: attrs[:comment] }
        end

        def add_utility_pin(pin_name, attrs = {})
          attrs = {
            type:    'Utility',
            comment: ''
          }.merge(attrs)
          pin_name = pin_name.to_sym unless pin_name.is_a? Symbol
          if UTL_TYPES.include? attrs[:type]
            type = attrs[:type]
          else
            Origen.log.error "Pinmap utility pin type '#{attrs[:type]}' must be set to one of the following: #{UTL_TYPES.join(', ')} for pin '#{pin_name}'"
            fail
          end
          @utility_pins[pin_name] = { type: attrs[:type], comment: attrs[:comment] }
        end

        def finalize(options = {})
        end

        def platform
          Origen.interface.platform
        end
      end
    end
  end
end
