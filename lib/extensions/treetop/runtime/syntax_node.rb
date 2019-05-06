require 'treetop'
require 'origen_testers/decompiler/node'

module Treetop
  module Runtime
    class SyntaxNode
      def n(type, *children)
        properties = children.last.is_a?(Hash) ? children.pop : {}
        OrigenTesters::Decompiler::Node.new(type, children, properties)
      end

      def elements_to_ast(elems = elements)
        elems.map do |e|
          if e.respond_to?(:to_ast)
            e.to_ast
          elsif e.nonterminal? && !e.elements.empty?
            elements_to_ast(e.elements)
          end
        end.compact.flatten
      end
    end
  end
end
