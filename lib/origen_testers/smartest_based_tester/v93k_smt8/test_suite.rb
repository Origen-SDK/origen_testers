module OrigenTesters
  module SmartestBasedTester
    class V93K_SMT8
      require 'origen_testers/smartest_based_tester/base/test_suite'
      class TestSuite < Base::TestSuite
        ATTRS =
          %w(
            name
            comment
            bypass

            test_method

            pattern
            specification
            seq
            burst

            spec_namespace
            spec_path
            seq_namespace
            seq_path
          )

        ALIASES = {
          spec:          :specification,
          test_function: :test_method
        }

        DEFAULTS = {
        }

        NO_STRING_TYPES = [:list_strings, :list_classes, :class]
        # Generate accessors for all attributes and their aliases
        ATTRS.each do |attr|
          if attr == 'name' || attr == 'pattern'
            attr_reader attr.to_sym
          else
            attr_accessor attr.to_sym
          end
        end

        # Define the aliases
        ALIASES.each do |_alias, val|
          define_method("#{_alias}=") do |v|
            send("#{val}=", v)
          end
          define_method("#{_alias}") do
            send(val)
          end
        end

        def lines
          # Initialize path setting
          # prefix = test method library prefix expectations
          # self.spec_namespace = instance override from the tester specification namespace
          # self.seq_namespace = instance override from the tester sequence namespace
          # self.spec_path = instance override from the tester specification path
          # self.seq_path = instance override from the tester sequence path
          if Origen.interface.respond_to? :custom_smt8_prefix
            prefix = Origen.interface.custom_smt8_prefix
          else
            prefix = 'measurement.'
          end
          spec_namespace = self.spec_namespace || tester.package_namespace
          spec_path      = self.spec_path || tester.spec_path
          seq_namespace  = self.seq_namespace || tester.package_namespace
          seq_path       = self.seq_path || tester.seq_path
          l = []
          l << "suite #{name} calls #{test_method.klass[0].downcase + test_method.klass[1..-1]} {"
          if pattern && !pattern.to_s.empty?
            l << "    #{prefix}pattern = setupRef(#{seq_namespace}.patterns.#{pattern});"
          end
          if seq && !seq.to_s.empty?
            l << "    #{prefix}operatingSequence = setupRef(#{seq_namespace}.#{seq_path}.#{seq});"
          end
          if burst && !burst.to_s.empty?
            l << "    #{prefix}operatingSequence = setupRef(#{seq_namespace}.#{seq_path}.#{burst});"
          end
          if specification && !specification.to_s.empty?
            l << "    #{prefix}specification = setupRef(#{spec_namespace}.#{spec_path}.#{specification});"
          end
          if bypass
            l << '    bypass = true;'
          end
          test_method.sorted_parameters.each do |param|
            name = param[0]
            unless name.is_a?(String)
              name = name.to_s[0] == '_' ? name.to_s.camelize(:upper) : name.to_s.camelize(:lower)
            end
            if param.last.is_a? Hash
              if !test_method.format(name).nil? && !test_method.format(name).is_a?(Hash)
                fail "#{name} parameter structure requires a Hash but value provided is #{test_method.format(name).class}"
              elsif test_method.format(name).nil? && tester.print_all_params
                l = add_nested_params(l, name, 'param0', {}, param.last, 1)
              elsif test_method.format(name).nil?
                # Do nothing
              else
                test_method.format(name).each do |key, meta_hash|
                  l = add_nested_params(l, name, key, meta_hash, param.last, 1)
                end
              end
            elsif NO_STRING_TYPES.include?(param.last) && test_method.format(param[0]).is_a?(String) && !test_method.format(param[0]).empty?
              l << "    #{name} = #{test_method.format(param[0])};"
            else
              l << "    #{name} = #{wrap_if_string(test_method.format(param[0]))};"
            end
          end
          l << '}'
          l
        end

        # rubocop:disable Metrics/ParameterLists: Avoid parameter lists longer than 5 parameters.
        def add_nested_params(l, name, key, value_hash, nested_params, nested_loop_count)
          nested_params_accepted_keys = []
          skip_keys                   = []
          unless value_hash.nil?
            unless value_hash.is_a?(Hash)
              fail "Provided value to nested params was not a Hash. Instead the value was #{value_hash.class}"
            end
            dynamic_spacing = ' ' * (4 * nested_loop_count)
            l << "#{dynamic_spacing}#{name}[#{key}] = {" unless name.nil?
            nested_params.each do |nested_param|
              # Guarentee hash is using all symbol keys
              # Since we cannot guarentee ruby version is greater than 2.5, we have to use an older syntax to
              value_hash = value_hash.inject({}) { |memo, (k, v)| memo[k.to_sym] = v; memo }
              nested_key = nested_param.first.to_s.gsub('.', '_').to_sym
              nested_key_underscore = nested_key.to_s.underscore.to_sym
              nested_params_accepted_keys << nested_key
              nested_params_accepted_keys << nested_key_underscore
              # We cannot create nested member functions with aliases
              # Requirement for hash parameter passing is to pass one of the key types and not both
              if value_hash.keys.include?(nested_key) &&
                 value_hash.keys.include?(nested_key_underscore) && nested_key != nested_key_underscore
                fail 'You are using a hash based test method and provided both the parameter name and alias name.'
              end
              nested_key = nested_key_underscore if value_hash.keys.include?(nested_key_underscore)
              if nested_param.last.first.is_a?(Hash) && value_hash[nested_key].is_a?(Hash)
                value_hash[nested_key].each do |inner_key, inner_meta_hash|
                  l = add_nested_params(l, nested_param.first, inner_key, value_hash.dig(nested_key, inner_key), nested_param.last.first, nested_loop_count + 1)
                  skip_keys << nested_key
                end
              elsif nested_param.last.first.is_a?(Hash) && tester.print_all_params
                l = add_nested_params(l, nested_param.first, 'param0', {}, nested_param.last.first, nested_loop_count + 1)
              end
              type = nested_param.last.first
              if NO_STRING_TYPES.include?(nested_param.last.first) && value_hash[nested_key] && !skip_keys.include?(nested_key)
                l << "    #{dynamic_spacing}#{nested_param.first} = #{test_method.handle_val_type(value_hash[nested_key], type, nested_param.first)};"
              elsif value_hash[nested_key] && !skip_keys.include?(nested_key)
                l << "    #{dynamic_spacing}#{nested_param.first} = #{wrap_if_string(test_method.handle_val_type(value_hash[nested_key], type, nested_param.first))};"
              elsif NO_STRING_TYPES.include?(nested_param.last.first) && !nested_param.last.last.is_a?(Hash) && tester.print_all_params && !skip_keys.include?(nested_key)
                l << "    #{dynamic_spacing}#{nested_param.first} = #{test_method.handle_val_type(nested_param.last.last, type, nested_param.first)};"
              elsif !nested_param.last.last.is_a?(Hash) && tester.print_all_params && !skip_keys.include?(nested_key)
                l << "    #{dynamic_spacing}#{nested_param.first} = #{wrap_if_string(test_method.handle_val_type(nested_param.last.last, type, nested_param.first))};"
              end
            end
            l << "#{dynamic_spacing}};" unless name.nil?
            # Sanity check there are not overpassed parameters
            value_hash.keys.each do |nested_key|
              unless nested_params_accepted_keys.include?(nested_key.to_sym)
                fail "You provided a parameter \'#{nested_key}\' that was not an accepted parameter to the hash parameter \'#{name}\'"
              end
            end
          end
          l
        end
        # rubocop:enable Metrics/ParameterLists: Avoid parameter lists longer than 5 parameters.

        def wrap_if_string(value)
          if value.is_a?(String)
            if value =~ /setupRef(.*)/
              # Do not wrap setupRef calls in quotes
              return value
            else
              "\"#{value}\""
            end
          else
            value
          end
        end
      end
    end
  end
end
