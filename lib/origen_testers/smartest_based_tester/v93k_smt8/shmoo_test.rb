module OrigenTesters
  module SmartestBasedTester
    class V93K_SMT8
      class ShmooTest
        ATTRS =
          %w(
            name

            bypass
            target
            result_title
            result_type
            result_signal
            execution_order
            ffc_error_count
            axis
          )

        ALIASES = {
          targets: :target,
          title:   :result_title,
          type:    :result_type,
          signal:  :result_signal
        }

        DEFAULTS = {
        }

        NO_STRING_TYPES = [:list_strings, :list_classes, :class]
        # Generate accessors for all attributes and their aliases
        ATTRS.each do |attr|
          if attr == 'name'
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
        attr_accessor :meta

        def initialize(name, attrs = {})
          @name = name
          if interface.unique_test_names == :signature
            if interface.flow.sig
              @name = "#{name}_#{interface.flow.sig}"
            end
          elsif interface.unique_test_names == :flowname || interface.unique_test_names == :flow_name
            @name = "#{name}_#{interface.flow.name.to_s.symbolize}"
          elsif interface.unique_test_names == :preflowname || interface.unique_test_names == :pre_flow_name
            @name = "#{interface.flow.name.to_s.symbolize}_#{name}"
          elsif interface.unique_test_names
            utn_string = interface.unique_test_names.to_s
            if utn_string =~ /^prepend_/
              utn_string = utn_string.gsub(/^prepend_/, '')
              @name = "#{utn_string}_#{name}"
            else
              utn_string = utn_string.gsub(/^append_/, '')
              @name = "#{name}_#{utn_string}"
            end
          end

          # handle axis
          if axis = attrs.delete(:axis)
            axis = [axis] unless axis.is_a?(Array)
            axis.each_with_index do |a, i|
              aname = a.delete(:name) || "axis#{i + 1}"
              if axes_names.include?(aname.to_sym)
                fail "Axis name #{aname} is already used in shmoo test '#{@name}'"
              end
              axes << ShmooTestAxis.new(aname.to_sym, a)
            end
          else
            fail 'ShmooTest must have at least one axis'
          end

          # Set the defaults
          self.class::DEFAULTS.each do |k, v|
            send("#{k}=", v)
          end
          # Then the values that have been supplied
          attrs.each do |k, v|
            send("#{k}=", v) if respond_to?("#{k}=") && k.to_sym != :name
          end
        end

        def smt8?
          tester.smt8?
        end

        def inspect
          "<ShmooTest: #{name}>"
        end

        # The name is immutable once the shmoo test is created, this will raise an error when called
        def name=(val, options = {})
          fail 'Once assigned the name of a shmoo test cannot be changed!'
        end

        def interface
          Origen.interface
        end

        def axes
          @axes ||= []
        end

        def axes_names
          axes.map(&:name)
        end

        def lines
          l = []
          l << "shmoo #{name} {"
          if target.length > 1
            l << "    target = \#[#{target.map(&:to_s).join(',')}];"
          else
            l << "    target = #{target[0]};"
          end
          l << "    resultTitle = \"#{result_title}\";" if result_title
          l << "    resultType = \"#{result_type}\";" if result_type
          l << "    resultSignal = \"#{result_signal}\";" if result_signal
          l << "    executionOrder = #{execution_order};" if execution_order
          l << "    bypass = \"#{bypass}\";" if bypass
          l << "    ffcErrorCount = #{ffc_error_count};" if ffc_error_count
          l << ''

          axes.each do |a|
            a.lines.each do |al|
              l << al
            end
          end

          l << '}'
          l
        end
      end

      class ShmooTestAxis
        ATTRS =
          %w(
            name

            resource_type
            resource_name
            setup_signal

            range_resolution
            range_steps
            range_fast_steps
            range_scale
            range_list
            range_start
            range_stop
            range_relative_percentage_start
            range_relative_percentage_stop
            range_relative_value_start
            range_relative_value_stop
            tracking
          )

        ALIASES = {
          resolution: :range_resolution,
          steps:      :range_steps,
          fast_steps: :range_fast_steps
        }

        # Generate accessors for all attributes and their aliases
        ATTRS.each do |attr|
          if attr == 'name'
            attr_reader attr.to_sym
          else
            attr_accessor attr.to_sym
          end
        end

        def initialize(name, attrs = {})
          @name = name

          @resource_type = attrs.delete(:resource_type)
          @resource_name = attrs.delete(:resource_name)
          @setup_signal = attrs.delete(:setup_signal)

          if range_list = attrs.delete(:range_list)
            @range_list = range_list
          elsif attrs[:range] && attrs[:range].is_a?(Array)
            @range_list = attrs.delete(:range)
          else
            if range = attrs.delete(:range)
              if range.is_a?(Range)
                @range_start = range.begin
                @range_stop = range.end
                @range_steps = attrs.delete(:range_steps) || attrs.delete(:steps)
                @range_resolution = attrs.delete(:range_resolution) || attrs.delete(:resolution)
                @range_fast_steps = attrs.delete(:range_fast_steps) || attrs.delete(:fast_steps)
              elsif range.is_a?(Hash)
                @range_start = range[:start]
                @range_stop = range[:stop]
                @range_steps = range[:steps]
                @range_resolution = range[:resolution]
                @range_fast_steps = range[:fast_steps]
              end
            elsif range_relative_percentage = attrs.delete(:range_relative_percentage)
              if range_relative_percentage.is_a?(Range)
                @range_relative_percentage_start = range_relative_percentage.begin
                @range_relative_percentage_stop = range_relative_percentage.end
                @range_steps = attrs.delete(:range_steps) || attrs.delete(:steps)
                @range_resolution = attrs.delete(:range_resolution) || attrs.delete(:resolution)
                @range_fast_steps = attrs.delete(:range_fast_steps) || attrs.delete(:fast_steps)
              elsif range_relative_percentage.is_a?(Hash)
                @range_relative_percentage_start = range_relative_percentage[:start]
                @range_relative_percentage_stop = range_relative_percentage[:stop]
                @range_steps = range_relative_percentage[:steps]
                @range_resolution = range_relative_percentage[:resolution]
                @range_fast_steps = range_relative_percentage[:fast_steps]
              end
            elsif range_relative_value = attrs.delete(:range_relative_value)
              if range_relative_value.is_a?(Range)
                @range_relative_value_start = range_relative_value.begin
                @range_relative_value_stop = range_relative_value.end
                @range_steps = attrs.delete(:range_steps) || attrs.delete(:steps)
                @range_resolution = attrs.delete(:range_resolution) || attrs.delete(:resolution)
                @range_fast_steps = attrs.delete(:range_fast_steps) || attrs.delete(:fast_steps)
              elsif range_relative_value.is_a?(Hash)
                @range_relative_value_start = range_relative_value[:start]
                @range_relative_value_stop = range_relative_value[:stop]
                @range_steps = range_relative_value[:steps]
                @range_resolution = range_relative_value[:resolution]
                @range_fast_steps = range_relative_value[:fast_steps]
              end
            else
              attrs.each do |k, v|
                send("#{k}=", v) if respond_to?("#{k}=") && k.to_sym != :name
              end
            end
          end

          if tracking = attrs.delete(:tracking)
            tracking = [tracking] unless tracking.is_a?(Array)
            tracking.each_with_index do |t, i|
              tname = t.delete(:name) || "tracking#{i + 1}"
              if trackings_names.include?(tname.to_sym)
                fail "Tracking name #{tname} is already used in shmoo test axis '#{@name}'"
              end
              trackings << ShmooTestTracking.new(tname.to_sym, t)
            end
          end

          attrs.each do |k, v|
            send("#{k}=", v) if respond_to?("#{k}=") && k.to_sym != :name
          end
        end

        def lines
          l = []
          l << "    axis [#{name}] = {"
          if resource_type
            l << "        resourceType = #{resource_type};"
          else
            fail 'Shmoo Axis must have a resource type'
          end
          if resource_name
            l << "        resourceName = \"#{resource_name}\";"
          else
            fail 'Shmoo Axis must have a resource name'
          end
          l << "        setup_signal = \"#{setup_signal}\";" if setup_signal
          if range_list
            l << "        range.list = \#[#{range_list.map(&:to_s).join(',')}];"
          elsif range_start && range_stop
            l << "        range.start = #{range_start};"
            l << "        range.stop = #{range_stop};"
          elsif range_relative_percentage_start && range_relative_percentage_stop
            l << "        range.relativePercentage.start = #{range_relative_percentage_start};"
            l << "        range.relativePercentage.stop = #{range_relative_percentage_stop};"
          elsif range_relative_value_start && range_relative_value_stop
            l << "        range.relativeValue.start = #{range_relative_value_start};"
            l << "        range.relativeValue.stop = #{range_relative_value_stop};"
          else
            fail 'Shmoo Axis must have a range (start & stop) or range list'
          end
          if range_resolution && range_steps.nil?
            l << "        range.resolution = #{range_resolution};"
            if range_fast_steps
              fail 'Shmoo Axis cannot have range fast steps with range resolution'
            end
          elsif range_steps && range_resolution.nil?
            l << "        range.steps = #{range_steps};"
            if range_fast_steps
              l << "        range.fastSteps = #{range_fast_steps};"
            end
          elsif range_resolution.nil? && range_steps.nil?
            fail 'Shmoo Axis must define either range resolution or range steps'
          else
            fail 'Shmoo Axis must define either range resolution or range steps, but not both'
          end
          l << '' if trackings.length > 0
          trackings.each do |t|
            t.lines.each do |tl|
              l << tl
            end
          end

          l << '    };'
          l
        end

        def trackings
          @trackings ||= []
        end

        def trackings_names
          trackings.map(&:name)
        end
      end

      class ShmooTestTracking
        ATTRS =
          %w(
            name

            resource_type
            resource_name
            setup_signal

            range_list
            range_start
            range_stop
            range_relative_percentage_start
            range_relative_percentage_stop
            range_relative_value_start
            range_relative_value_stop
          )

        # Generate accessors for all attributes and their aliases
        ATTRS.each do |attr|
          if attr == 'name'
            attr_reader attr.to_sym
          else
            attr_accessor attr.to_sym
          end
        end

        def initialize(name, attrs = {})
          @name = name

          @resource_type = attrs.delete(:resource_type)
          @resource_name = attrs.delete(:resource_name)
          @setup_signal = attrs.delete(:setup_signal)

          if range = attrs.delete(:range)
            if range.is_a?(Range)
              @range_start = range.begin
              @range_stop = range.end
            elsif range.is_a?(Hash)
              @range_start = range[:start]
              @range_stop = range[:stop]
            elsif range.is_a?(Array)
              @range_list = range
            end
          elsif range_relative_percentage = attrs.delete(:range_relative_percentage)
            if range_relative_percentage.is_a?(Range)
              @range_relative_percentage_start = range_relative_percentage.begin
              @range_relative_percentage_stop = range_relative_percentage.end
            elsif range_relative_percentage.is_a?(Hash)
              @range_relative_percentage_start = range_relative_percentage[:start]
              @range_relative_percentage_stop = range_relative_percentage[:stop]
            end
          elsif range_relative_value = attrs.delete(:range_relative_value)
            if range_relative_value.is_a?(Range)
              @range_relative_value_start = range_relative_value.begin
              @range_relative_value_stop = range_relative_value.end
            elsif range_relative_value.is_a?(Hash)
              @range_relative_value_start = range_relative_value[:start]
              @range_relative_value_stop = range_relative_value[:stop]
            end
          else
            attrs.each do |k, v|
              send("#{k}=", v) if respond_to?("#{k}=") && k.to_sym != :name
            end
          end
        end

        def lines
          l = []
          l << "        tracking [#{name}] = {"
          if resource_type
            l << "            resourceType = #{resource_type};"
          else
            fail 'Shmoo Tracking must have a resource type'
          end
          if resource_name
            l << "            resourceName = \"#{resource_name}\";"
          else
            fail 'Shmoo Tracking must have a resource name'
          end
          l << "            setup_signal = \"#{setup_signal}\";" if setup_signal
          if range_list
            l << "            range.list = \#[#{range_list.map(&:to_s).join(',')}];"
          elsif range_start && range_stop
            l << "            range.start = #{range_start};"
            l << "            range.stop = #{range_stop};"
          elsif range_relative_percentage_start && range_relative_percentage_stop
            l << "            range.relativePercentage.start = #{range_relative_percentage_start};"
            l << "            range.relativePercentage.stop = #{range_relative_percentage_stop};"
          elsif range_relative_value_start && range_relative_value_stop
            l << "            range.relativeValue.start = #{range_relative_value_start};"
            l << "            range.relativeValue.stop = #{range_relative_value_stop};"
          else
            fail 'Shmoo Tracking must have a range (start & stop) or range list'
          end
          l << '        };'
          l
        end
      end
    end
  end
end
