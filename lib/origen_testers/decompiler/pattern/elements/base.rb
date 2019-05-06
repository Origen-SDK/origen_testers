module OrigenTesters
  module Decompiler
    class Pattern
      class Base
        attr_reader :ast
        attr_reader :decompiled_pattern
        attr_reader :processor

        def initialize(ast:, decompiled_pattern:, **options)
          @decompiled_pattern = decompiled_pattern
          @ast = ast

          # @processor = decompiled_pattern.select_processor.call(
          #  node: ast, source: @source,
          #  decompiled_pattern: decompiled_pattern
          # ).new.run(ast, decompiled_pattern: decompiled_pattern)

          if decompiled_pattern.respond_to?(:select_processor)
            @processor = decompiled_pattern.select_processor(
              node:               ast,
              source:             @source,
              decompiled_pattern: decompiled_pattern
            )
            if @processor
              @processor = @processor.new.run(ast, decompiled_pattern: decompiled_pattern)
            end
          end

          if @processor.nil? && decompiled_pattern.include_vector_based_grammar?
            @processor = OrigenTesters::Decompiler::BaseGrammar::VectorBased::Processors.select_processor(ast, decompiled_pattern: decompiled_pattern)
            if @processor
              @processor = @processor.new.run(ast, decompiled_pattern: decompiled_pattern)
            end
          end

          if @processor.nil?
            Origen.app.fail(exception_class: NoAvailableProcessor, message: "Could not match processor for AST type :#{ast.type}")
          end
        end

        def [](node)
          processor.find(node)
        end

        def _platform_nodes_
          processor.platform_nodes.each_with_object({}) { |n, h| h[n] = processor.send(n) }
        end

        def platform_nodes
          _platform_nodes_
        end

        def method_missing(m, *args, &block)
          if _platform_nodes_.include?(m)
            processor.send(m)
          else
            super
          end
        end

        def execute!
          if processor.execute?
            processor.execute!(self)
          end
        end

        def pinlist
          decompiled_pattern.pinlist.pinlist
        end
      end
    end
  end
end
