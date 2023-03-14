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
          )

        ALIASES = {
          spec:          :specification,
          test_function: :test_method
        }

        DEFAULTS = {
        }

        SKIP_LINES = %w(
          pattern
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
          l = []
          l << "suite #{name} calls #{test_method.klass[0].downcase + test_method.klass[1..-1]} {"
          if pattern && !pattern.to_s.empty?
            l << "    measurement.pattern = setupRef(#{tester.package_namespace}.patterns.#{pattern});"
          end
          if seq && !seq.to_s.empty?
            l << "    measurement.operatingSequence = setupRef(#{seq});"
          end
          if specification && !specification.to_s.empty?
            l << "    measurement.specification = setupRef(#{tester.package_namespace}.#{tester.spec_path}.#{specification});"
            # l << "    measurement.specification = setupRef(mainSpecs.#{specification});"
          end
          test_method.sorted_parameters.each do |param|
            name = param[0]
            unless name.is_a?(String)
              name = name.to_s[0] == '_' ? name.to_s.camelize(:upper) : name.to_s.camelize(:lower)
            end

            if test_method.format(param[0]).is_a?(String) && !test_method.format(param[0]).empty? && !SKIP_LINES.include?(name)
              l << "    #{name} = #{wrap_if_string(test_method.format(param[0]))};"
            end
          end
          l << '}'
          l
        end
      end
    end
  end
end
