module OrigenTesters
  module Decompiler
    module Nodes
      class Node
        attr_reader :context
        attr_reader :type

        def self.inherited(subclass)
          if subclass.const_defined?(:PLATFORM_NODES)
            subclass.const_get(:PLATFORM_NODES).each do |n|
              subclass.define_instance_method(n) do
                instance_variable_get(":@#{n}")
              end
            end
          end
        end

        def initialize(context:, type:, **nodes)
          @context = context
          if type
            @type = type
          elsif @type.nil?
            type = self.class.underscore
          end

          unless platform_nodes.empty?
            platform_nodes.each do |n|
              define_singleton_method(n) do
                instance_variable_get("@#{n}".to_sym)
              end
            end
          end
        end

        def execute?
          @execute
        end

        def platform_nodes
          self.class.const_defined?(:PLATFORM_NODES) ? self.class.const_get(:PLATFORM_NODES) : []
        end
      end

      class CommentBlock < OrigenTesters::Decompiler::Nodes::Node
        attr_reader :comments

        def initialize(comments:, context:)
          @comments = comments
          super(context: context, type: :comment_block)
        end

        def execute?
          true
        end

        def execute!(context)
          @comments.each { |c| cc(c) }
        end
      end

      class Vector < OrigenTesters::Decompiler::Nodes::Node
        attr_reader :repeat
        attr_reader :timeset
        attr_reader :pin_states
        attr_reader :comment

        # rubocop:disable Metrics/ParameterLists
        def initialize(repeat:, timeset:, pin_states:, comment:, context:, **nodes)
          @execute = true

          @repeat = repeat
          @timeset = timeset
          @pin_states = pin_states
          @comment = comment

          super(context: context, type: :vector)
        end
        # rubocop:enable Metrics/ParameterLists

        def execute!(context)
          # Apply a timeset switch, if needed.
          unless Origen.tester.timeset.name == timeset
            Origen.tester.set_timeset(timeset)
          end

          # Apply the comment
          unless comment.empty?
            cc(comment)
          end

          # Apply the pin states
          context.pinlist.each_with_index do |pin, i|
            dut.pins(pin).vector_formatted_value = pin_states[i]
          end

          # Cycle the tester
          repeat.cycles
        end
      end

      class Pinlist < OrigenTesters::Decompiler::Nodes::Node
        attr_reader :pins
        alias_method :pinlist, :pins

        def initialize(pins:, context:)
          @pins = pins.map(&:to_sym)
          super(context: context, type: :pinlist)
        end
      end

      class Frontmatter < OrigenTesters::Decompiler::Nodes::Node
        attr_reader :comments
        attr_reader :pattern_header

        alias_method :header, :pattern_header
        alias_method :comment_header, :pattern_header

        def initialize(context:, pattern_header: nil, comments: nil)
          @pattern_header = pattern_header
          @comments = comments || []

          super(context: context, type: :frontmatter)
        end

        def execute!(context)
          pattern_header.each do |c|
            cc(c)
          end

          comments.each do |c|
            cc(c)
          end
        end

        def execute?
          true
        end
      end
    end
  end
end
