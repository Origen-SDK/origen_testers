module OrigenTesters
  module Decompiler
    class Pattern
      class Base
        attr_reader :context
        alias_method :decompiled_pattern, :context

        attr_reader :node
        alias_method :processor, :node

        def initialize(node:, context:, **options)
          @context = context
          @node = node
        end

        def [](node)
          node.find(node)
        end

        def _platform_nodes_
          node.platform_nodes.each_with_object({}) { |n, h| h[n] = node.send(n) }
        end

        def platform_nodes
          _platform_nodes_
        end

        def method_missing(m, *args, &block)
          if _platform_nodes_.include?(m) || node.respond_to?(m)
            node.send(m)
          else
            super
          end
        end

        def execute!
          if node.execute?
            node.execute!(self)
          end
        end

        def pinlist
          decompiled_pattern.pinlist.pinlist
        end
      end
    end
  end
end
