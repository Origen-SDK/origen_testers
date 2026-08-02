module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestMethod
        FORMAT_TYPES = [:current, :voltage, :time, :frequency, :string, :integer, :double, :boolean, :class, :list_strings, :list_classes]

        def self.parameter_sort_keys
          @@parameter_sort_keys ||= {}
        end

        def self.installed_dynamic_methods
          @installed_dynamic_methods ||= {}
        end

        def self.underscored_parameter_names
          @@underscored_parameter_names ||= {}
        end

        def self.underscore_parameter_name(name)
          underscored_parameter_names[name] ||= name.underscore
        end

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
        alias_method :limit_id, :limits_id
        alias_method :limit_id=, :limits_id=
        # Used to store the name of the primary test logged in SMT8
        attr_accessor :sub_test_name

        def initialize(options)
          @type = options[:type]
          @library = options[:library]
          @class_name = options[:methods].delete(:class_name)
          @parameters = {}
          @limits_id = options[:methods].delete(:limits_id) || options[:methods].delete(:limit_id)
          @limits = TestMethods::Limits.new(self)
          @limits.render = false if options[:methods].delete(:render_limits_in_tf) == false
          # Add any methods
          if options[:methods][:methods]
            methods = options[:methods][:methods]
            @finalize = methods[:finalize]
            methods.each do |method_name, function|
              unless method_name == :finalize
                var_name = "@#{method_name}".gsub(/=|\?/, '_')
                instance_variable_set(var_name, function)
                unless self.class.installed_dynamic_methods[method_name]
                  self.class.send(:define_method, method_name) do |*args|
                    instance_variable_get(var_name).call(self, *args)
                  end
                  self.class.installed_dynamic_methods[method_name] = true
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
              underscored_attr = self.class.underscore_parameter_name(clean_attr)
              aliases << underscored_attr if underscored_attr != clean_attr
              aliases.each do |alias_|
                setter = :"#{alias_}="
                unless self.class.installed_dynamic_methods[setter]
                  self.class.send(:define_method, setter) do |v|
                    v = v.to_s if v.is_a?(Symbol)
                    if allowed
                      unless allowed.include?(v)
                        fail "Cannot set #{alias_} to #{v}, valid values are: #{allowed.join(', ')}"
                      end
                    end
                    instance_variable_set("@#{clean_attr}", v)
                  end
                  self.class.installed_dynamic_methods[setter] = true
                end
                alias_name = alias_.to_sym
                unless self.class.installed_dynamic_methods[alias_name]
                  self.class.send(:define_method, alias_name) do
                    instance_variable_get("@#{clean_attr}")
                  end
                  self.class.installed_dynamic_methods[alias_name] = true
                end
              end
              send("#{clean_attr}=", default)
            end
          end
          if options[:methods][:aliases]
            options[:methods][:aliases].each do |alias_, attr|
              clean_attr = clean_attr_name(attr)
              setter = :"#{alias_}="
              unless self.class.installed_dynamic_methods[setter]
                self.class.send(:define_method, setter) do |v|
                  send("#{clean_attr}=", v)
                end
                self.class.installed_dynamic_methods[setter] = true
              end
              alias_name = alias_.to_sym
              unless self.class.installed_dynamic_methods[alias_name]
                self.class.send(:define_method, alias_name) do
                  send(clean_attr)
                end
                self.class.installed_dynamic_methods[alias_name] = true
              end
            end
          end
          # Finally set any initial values that have been supplied
          options[:attrs].each do |k, v|
            accessor = "#{k}="
            if respond_to?(accessor)
              send(accessor, v)
            else
              accessor = "#{self.class.underscore_parameter_name(k.to_s)}="
              send(accessor, v) if respond_to?(accessor)
            end
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
            elsif parameters[attr].is_a?(Hash) || parameters[attr.to_sym].is_a?(Hash)
              type = :hash
            else
              fail "Unknown attribute type: #{parameters[attr]}"
            end
          end
          if val.nil? && !tester.print_all_params
            nil
          else
            handle_val_type(val, type, attr)
          end
        end

        def handle_val_type(val, type, attr)
          return val if val == '' && !tester.smt8?

          case type
          when :current, 'CURR'
            "#{val}[A]"
          when :voltage, 'VOLT'
            "#{val}[V]"
          when :time
            "#{val}[s]"
          when :frequency
            "#{val}[Hz]"
          when :string
            val.to_s
          when :integer
            val.to_i
          when :double
            val.to_f
          when :boolean
            # Check for valid values
            if [0, 1, true, false, 'true', 'false'].include?(val)
              # Use true/false for smt8 and 0/1 for smt7
              if [1, true, 'true'].include?(val)
                tester.smt8? ? true : 1
              else
                tester.smt8? ? false : 0
              end
            else
              fail "Unknown boolean value for attribute #{attr}: #{val}"
            end
          when :hash, :class
            val
          when :list_strings
            unless val.is_a?(Array)
              fail "#{val} is not an Array. List_strings must have Array values"
            end

            "##{val}"
          when :list_classes
            unless val.is_a?(Array)
              fail "#{val} is not an Array. List_classes must have Array values"
            end

            "##{val.to_s.gsub('"', '')}"
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
            self.class.parameter_sort_keys[name] ||= begin
              if name.is_a?(String)
                name
              elsif name.to_s[0] == '_'
                name.to_s.camelize(:upper)
              else
                name.to_s.camelize(:lower)
              end
            end
          end
        end

        def remove_parameter(name)
          @parameters.delete(name)
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
