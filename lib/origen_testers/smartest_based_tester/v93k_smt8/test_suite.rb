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
          )

        ALIASES = {
          spec:          :specification,
          test_function: :test_method
        }

        DEFAULTS = {
        }

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
          l = []
          l << "suite #{name} calls #{test_method.klass} {"
          if pattern && !pattern.to_s.empty?
            l << "    measurement.pattern = setupRef(#{tester.package_namespace}.patterns.#{pattern});"
          end
          if specification && !specification.to_s.empty?
            l << "    measurement.specification = setupRef(#{tester.package_namespace}.specs.#{specification});"
          end
          parameters_to_include = programmed_parameters.nil? ? test_method.sorted_parameters : filter_parameters(test_method.sorted_parameters)
          parameters_to_include.each do |param|
            name = param[0]
            unless name.is_a?(String)
              name = name.to_s[0] == '_' ? name.to_s.camelize(:upper) : name.to_s.camelize(:lower)
            end
            l << "    #{name} = #{wrap_if_string(test_method.format(param[0]))};"
          end
          l << '}'
          l
        end

        private

        def filter_parameters(param_ary)
          [].tap do |filtered_ary|
            param_ary.each do |param_definition|
              name = param_definition.first
              next unless programmed_parameters.include? name
              filtered_ary << param_definition
            end
          end
        end
      end
    end
  end
end
