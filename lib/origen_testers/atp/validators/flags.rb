module OrigenTesters::ATP
  module Validators
    class Flags < Validator
      def setup
        @open_if_nodes = []
        @open_unless_nodes = []
        @conflicting = []
      end

      def on_completion
        failed = false
        unless @conflicting.empty?
          error 'if_flag and unless_flag conditions cannot be nested and refer to the same flag unless it is declared as volatile'
          error "The following conflicts were found in flow #{flow.name}:"
          @conflicting.each do |a, b|
            a_condition = a.to_a[1] ? 'if_job:    ' : 'unless_job:'
            b_condition = b.to_a[1] ? 'if_job:    ' : 'unless_job:'
            error "  #{a.type}(#{a.to_a[0]}) #{a.source}"
            error "  #{b.type}(#{b.to_a[0]}) #{b.source}"
            error ''
          end
          failed = true
        end
        failed
      end

      def on_flow(node)
        extract_volatiles(node)
        process_all(node.children)
      end

      def on_if_flag(node)
        if volatile?(node.to_a[0])
          process_all(node.children)
        else
          if n = @open_unless_nodes.find { |n| n.to_a[0] == node.to_a[0] }
            @conflicting << [n, node]
          end
          @open_if_nodes << node
          process_all(node.children)
          @open_if_nodes.pop
        end
      end

      def on_unless_flag(node)
        if volatile?(node.to_a[0])
          process_all(node.children)
        else
          if n = @open_if_nodes.find { |n| n.to_a[0] == node.to_a[0] }
            @conflicting << [n, node]
          end
          @open_unless_nodes << node
          process_all(node.children)
          @open_unless_nodes.pop
        end
      end
    end
  end
end
