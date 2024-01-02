module OrigenTesters
  module SmartestBasedTester
    class V93K_SMT8
      require 'origen_testers/smartest_based_tester/base/test_suite'
      class TestSuite < Base::TestSuite
        ATTRS =
          %w(
            name
            comment

            test_method

            pattern
            specification
            seq
            burst
          )

        ALIASES = {
          spec:          :specification,
          test_function: :test_method
        }

        DEFAULTS = {
        }

        SKIP_LINES = %w(
          # pattern
          # binning.binnable
        )
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
          if Origen.interface.respond_to? :custom_st8_prefix
            prefix = Origen.interface.custom_st8_prefix
          else
            prefix = 'measurement.'
          end
          l = []
          l << "suite #{name} calls #{test_method.klass[0].downcase + test_method.klass[1..-1]} {"
          if pattern && !pattern.to_s.empty?
            l << "    #{prefix}pattern = setupRef(#{tester.package_namespace}.patterns.#{pattern});"
          end
          if seq && !seq.to_s.empty?
            l << "    #{prefix}operatingSequence = setupRef(#{tester.package_namespace}.#{tester.seq_path}.#{seq});"
          end
          if burst && !burst.to_s.empty?
            l << "    #{prefix}operatingSequence = setupRef(#{tester.package_namespace}.#{tester.seq_path}.#{burst});"
          end
          if specification && !specification.to_s.empty?
            l << "    #{prefix}specification = setupRef(#{tester.package_namespace}.#{tester.spec_path}.#{specification});"
          end
          test_method.sorted_parameters.each do |param|
            name = param[0]
            unless name.is_a?(String)
              name = name.to_s[0] == '_' ? name.to_s.camelize(:upper) : name.to_s.camelize(:lower)
            end
            if [true, false].include? test_method.format(param[0])
              l << "    #{name} = #{wrap_if_string(test_method.format(param[0]))};"
            elsif test_method.format(param[0]).is_a?(String) && !test_method.format(param[0]).empty? && !SKIP_LINES.include?(name)
              l << "    #{name} = #{wrap_if_string(test_method.format(param[0]))};"
            elsif param.last.is_a? Hash
              if !test_method.format(name).nil? && !test_method.format(name).is_a?(Hash)
                fail "#{name} parameter structure requires a Hash but value provided is #{test_method.format(name).class}"
              elsif test_method.format(name).nil?
                # Don't populate the test_suite if nothing has been provided
              else
                test_method.format(name).each do |key, meta_hash|
                  l = add_nested_params(l, name, key, meta_hash, param.last, 1)
                end
              end
            end
          end
          l << '}'
          l
        end

        # rubocop:disable Metrics/ParameterLists: Avoid parameter lists longer than 5 parameters.
        def add_nested_params(l, name, key, value_hash, nested_params, nested_loop_count)
          nested_params_accepted_keys = []
          skip_keys                   = []
          debugger if name == 'softset'
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
              nested_key = nested_param.first.to_sym
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
              end
              if value_hash[nested_key] && !skip_keys.include?(nested_key)
                l << "    #{dynamic_spacing}#{nested_param.first} = #{wrap_if_string(value_hash[nested_key])};"
              elsif !nested_param.last.last.is_a?(Hash) && tester.print_all_params && !skip_keys.include?(nested_key)
                l << "    #{dynamic_spacing}#{nested_param.first} = #{wrap_if_string(nested_param.last.last)};"
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
      end
    end
  end
end
