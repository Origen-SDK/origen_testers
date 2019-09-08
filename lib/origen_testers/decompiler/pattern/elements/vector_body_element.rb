module OrigenTesters
  module Decompiler
    class Pattern
      require_relative './base'

      class VectorBodyElement < Base
        # The known vector element types, supported regardless of the tester/platform.
        BASE_ELEMENTS = [:vector, :comment_block]

        attr_reader :type
        attr_reader :element
        attr_reader :vector_index

        def initialize(node:, context:, **options)
          @source = :vector_body_element
          super(node: node, context: context)
          @type = node.type
          @vector_index = options[:vector_index]

          # If the processor is a :vector or a comment_block, we can deal with
          # this automatically. We also know that neither of these elemnts are
          # platform specific.
          @element = (BASE_ELEMENTS.include?(type)) ? to_element : false
        end

        # Returns an element class (e.g., Vector) that casts itself to a known vector-element type.
        # For example, if this element's processor is a 'vector', then it can cast itself to a Vector class,
        #   to expose functionality (e.g., #timeset) on the class itself. Otherwise, the functionality will remain
        #   on the processor and its up to the user to know what the processor has.
        # @note Calling this not required, as this is just an interface to a known processor type.
        def to_element
          if type == :comment_block
            CommentBlock.new(self)
          elsif type == :vector
            Vector.new(self)
          else
            fail "Could not cast platform-specific vector body element type :#{type} to a standalone class!"
          end
        end

        def to_yaml_hash(options = {})
          {
            class:        self.class.to_s,
            vector_index: vector_index
          }.merge(
            begin
              if element
                element.to_yaml_hash(options)
              else
                # If this element couldn't be matched, provide a simple yaml hash
                # including some basic elements.
                {
                  type:           type,
                  processor:      processor.class.to_s,
                  platform_nodes: _platform_nodes_
                }
              end
            end
          )
        end

        def is_a_vector?
          type == :vector
        end
        alias_method :is_vector?, :is_a_vector?
        alias_method :vector?, :is_a_vector?

        def platform
          decompiled_pattern.platform
        end
        alias_method :tester, :platform

        def platform?(p = nil)
          decompiled_pattern.platform?(p)
        end
        alias_method :tester?, :platform?

        def decompiler
          decompiled_pattern.platform
        end

        def decompiler?(d = nil)
          decompiled_pattern.decompiler?(d)
        end

        def is_a_comment?
          type == :comment || type == :comment_block
        end
        alias_method :is_comment?, :is_a_comment?

        def is_tester_specific?
          platform_nodes.include?(type)
        end
        alias_method :is_tester_specific_element?, :is_tester_specific?
        alias_method :is_platform_specific?, :is_tester_specific?
        alias_method :is_platform_specific_element?, :is_tester_specific?
        alias_method :is_decompiler_specific?, :is_tester_specific?
        alias_method :is_decompiler_specific_element?, :is_tester_specific?
        alias_method :is_a_tester_specific_element?, :is_tester_specific?
        alias_method :is_a_platform_specific_element?, :is_tester_specific?
        alias_method :is_a_decompiler_specific_element?, :is_tester_specific?
      end
    end
  end
end
