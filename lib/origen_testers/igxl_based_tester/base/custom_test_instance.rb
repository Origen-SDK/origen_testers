module OrigenTesters
  module IGXLBasedTester
    class Base
      class CustomTestInstance
        attr_accessor :type, :index, :version, :append_version, :finalize

        # Returns the object representing the test instance library that the
        # given test instance is defined in
        attr_reader :library

        def self.define
          # Generate accessors for all attributes and their aliases
          attrs.each do |attr|
            writer = "#{attr}=".to_sym
            reader = attr.to_sym
            attr_reader attr.to_sym unless method_defined? reader
            attr_writer attr.to_sym unless method_defined? writer
          end

          # Define the common aliases now, the instance type specific ones will
          # be created when the instance type is known
          self::TEST_INSTANCE_ALIASES.each do |_alias, val|
            writer = "#{_alias}=".to_sym
            reader = _alias.to_sym
            unless val.is_a? Hash
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
        end

        def self.attrs
          @attrs ||= begin
            attrs = self::TEST_INSTANCE_ATTRS.dup

            self::TEST_INSTANCE_EXTRA_ARGS.times do |i|
              attrs << "arg#{i}"
            end
            attrs << 'comment'
            attrs
          end
        end

        def initialize(name, options = {})
          @append_version = true
          self.name = name
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
          options[:methods].each do |attr, arg_default|
            arg_default = [arg_default] unless arg_default.is_a?(Array)
            unless attr == :aliases || attr == :methods
              clean_attr = clean_attr_name(attr)
              arg = arg_default[0]
              default = arg_default[1]
              allowed = arg_default[2]
              aliases = [clean_attr]
              aliases << clean_attr.underscore if clean_attr.underscore != clean_attr
              aliases.each do |alias_|
                define_singleton_method("#{alias_}=") do |v|
                  if allowed
                    unless allowed.include?(v)
                      fail "Cannot set #{alias_} to #{v}, valid values are: #{allowed.join(', ')}"
                    end
                  end
                  instance_variable_set("@#{arg}", v)
                end
                define_singleton_method(alias_) do
                  instance_variable_get("@#{arg}")
                end
              end
              send("#{arg}=", default)
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
          # Set the defaults
          self.class::TEST_INSTANCE_DEFAULTS.each do |k, v|
            send("#{k}=", v) if self.respond_to?("#{k}=", v)
          end
          # Finally set any initial values that have been supplied
          options[:attrs].each do |k, v|
            send("#{k}=", v) if respond_to?("#{k}=")
          end
        end

        def ==(other_instance)
          self.class == other_instance.class &&
            unversioned_name.to_s == other_instance.unversioned_name.to_s &&
            self.class.attrs.all? do |attr|
              # Exclude test name, already examined above and don't want to include
              # the version in the comparison
              if attr == 'test_name'
                true
              else
                send(attr) == other_instance.send(attr)
              end
            end
        end

        # Returns the fully formatted test instance for insertion into an instance sheet
        def to_s(override_name = nil)
          l = "\t"
          self.class.attrs.each do |attr|
            if attr == 'test_name' && override_name
              l += "#{override_name}\t"
            else
              l += "#{send(attr)}\t"
            end
          end
          "#{l}"
        end

        def name
          if version && @append_version
            "#{@test_name}_v#{version}"
          else
            @test_name.to_s
          end
        end
        alias_method :test_name, :name

        def name=(val)
          self.test_name = val
        end

        def unversioned_name
          @test_name.to_s
        end

        private

        def clean_attr_name(name)
          name.to_s.gsub(/\.|-/, '_')
        end
      end
    end
  end
end
