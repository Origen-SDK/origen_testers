module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestMethod
        FORMAT_TYPES = [:current, :voltage, :time, :string, :integer, :double]

        # Returns the object representing the test method library that the
        # given test method is defined in
        attr_reader :library
        attr_reader :type
        attr_reader :id
        alias_method :name, :id
        # Returns an hash corresponding to the parameters that the given test method has.
        # The keys are the parameter names and the values are the parameter type.
        attr_reader :parameters
        attr_accessor :class_name
        attr_accessor :abs_class_name
        attr_reader :limits
        attr_accessor :limits_id

        def initialize(options)
          @type = options[:type]
          @library = options[:library]
          @class_name = options[:methods].delete(:class_name)
          @parameters = {}
          @limits_id = options[:methods].delete(:limits_id)
          @limits = TestMethods::Limits.new(self)
          # Add any methods
          if options[:methods][:methods]
            methods = options[:methods][:methods]
            @finalize = methods[:finalize]
            methods.each do |method_name, function|
              unless method_name == :finalize
                var_name = "@#{method_name}".gsub(/=|\?/, '_')
                instance_variable_set(var_name, function)
                define_singleton_method method_name do |*args|
                  instance_variable_get(var_name).call(self, *args)
                end
              end
            end
          end
          # Create attributes corresponding to the test method type represented
          # by this method instance
          options[:methods].each do |attr, type_default|
            unless attr == :limits_type || attr == :aliases || attr == :methods
              clean_attr = clean_attr_name(attr)
              type = type_default[0]
              default = type_default[1]
              allowed = type_default[2]
              @parameters[attr] = type
              aliases = [clean_attr]
              aliases << clean_attr.underscore if clean_attr.underscore != clean_attr
              aliases.each do |alias_|
                define_singleton_method("#{alias_}=") do |v|
                  v = v.to_s if v.is_a?(Symbol)
                  if allowed
                    unless allowed.include?(v)
                      fail "Cannot set #{alias_} to #{v}, valid values are: #{allowed.join(', ')}"
                    end
                  end
                  instance_variable_set("@#{clean_attr}", v)
                end
                define_singleton_method(alias_) do
                  instance_variable_get("@#{clean_attr}")
                end
              end
              send("#{clean_attr}=", default)
            end
          end
          if options[:methods][:aliases]
            options[:methods][:aliases].each do |alias_, attr|
              clean_attr = clean_attr_name(attr)
              define_singleton_method("#{alias_}=") do |v|
                send("#{clean_attr}=", v)
              end
              define_singleton_method(alias_) do
                send(clean_attr)
              end
            end
          end
          # Finally set any initial values that have been supplied
          options[:attrs].each do |k, v|
            send("#{k}=", v) if respond_to?("#{k}=")
          end
        end

        def format(attr)
          clean_attr = clean_attr_name(attr)
          val = send(clean_attr)
          if FORMAT_TYPES.include?(parameters[attr])
            type = parameters[attr]
          else
            # The type is based on the value of another attribute
            name = clean_attr_name(parameters[attr])
            if respond_to?(name)
              type = send(name)
            elsif respond_to?(name.sub(/b$/, ''))
              type = inverse_of(send(name.sub(/b$/, '')))
            else
              fail "Unknown attribute type: #{parameters[attr]}"
            end
          end
          case type
          when :current, 'CURR'
            "#{val}[A]"
          when :voltage, 'VOLT'
            "#{val}[V]"
          when :time
            "#{val}[s]"
          when :frequency
            "#{val}[Hz]"
          when :string, :integer, :double
            val.to_s
          else
            fail "Unknown type for attribute #{attr}: #{type}"
          end
        end

        def klass
          @abs_class_name ||
            "#{library.klass}.#{@class_name || type.to_s.camelize}"
        end

        def finalize
          @finalize
        end

        def method_missing(method, *args, &block)
          if limits && limits.respond_to?(method)
            limits.send(method, *args, &block)
          else
            super
          end
        end

        def respond_to?(method)
          (limits && limits.respond_to?(method)) || super
        end

        def sorted_parameters
          @parameters.sort_by do |name|
            if name.is_a?(String)
              name
            else
              if name.to_s[0] == '_'
                name.to_s.camelize(:upper)
              else
                name.to_s.camelize(:lower)
              end
            end
          end
        end

        private

        def inverse_of(type)
          case type
          when :current, 'CURR'
            :voltage
          when :voltage, 'VOLT'
            :current
          else
            fail "Don't know the inverse of type: #{type}"
          end
        end

        def clean_attr_name(name)
          name.to_s.gsub(/\.|-|\s+/, '_')
        end

        def id=(val)
          @id = val
        end
      end
    end
  end
end
