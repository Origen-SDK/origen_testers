require 'ast'
module OrigenTesters::ATP
  module AST
    class Extractor
      include ::AST::Processor::Mixin

      attr_reader :types
      attr_reader :results

      def process(node, types = nil)
        if types
          @types = types
          @results = []
          # node = AST::Node.new(:wrapper, node) unless node.respond_to?(:to_ast)
        end
        super(node) if node.respond_to?(:to_ast)
        results
      end

      def handler_missing(node)
        @results << node if types.include?(node.type)
        process_all(node.children)
      end
    end
  end
end
