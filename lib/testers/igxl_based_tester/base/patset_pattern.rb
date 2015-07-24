module Testers
  module IGXLBasedTester
    class Base
      class PatsetPattern
        ALIASES = {
          pattern: :file_name
        }

        def self.define
          # Generate accessors for all attributes and their aliases
          self::PATSET_ATTRS.each do |attr|
            writer = "#{attr}=".to_sym
            reader = attr.to_sym
            attr_reader attr.to_sym unless method_defined? reader
            attr_writer attr.to_sym unless method_defined? writer
          end

          ALIASES.each do |_alias, val|
            writer = "#{_alias}=".to_sym
            reader = _alias.to_sym
            unless method_defined? writer
              define_method("#{_alias}=") do |v|
                send("#{val}=", v)
              end
            end
            unless method_defined? reader
              define_method("#{_alias}") do
                send(val)
              end
            end
          end
        end

        def initialize(patset, attrs = {})
          # Set the defaults
          self.class::PATSET_DEFAULTS.each do |k, v|
            send("#{k}=", v)
          end
          # Then the values that have been supplied
          self.pattern_set = patset
          attrs.each do |k, v|
            send("#{k}=", v)
          end
        end

        def to_s
          l = "\t"
          self.class::PATSET_ATTRS.each do |attr|
            l += "#{send(attr)}\t"
          end
          "#{l}"
        end
      end
    end
  end
end
