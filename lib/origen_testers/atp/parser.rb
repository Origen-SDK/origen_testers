require 'sexpistol'
module OrigenTesters::ATP
  class Parser < Sexpistol::Parser
    def initialize
      # This accessor moves to Sexpistol::Parser in newer versions of the gem
      # self.ruby_keyword_literals = true
    end

    def string_to_ast(string)
      # to_sexp(parse_string(string))
      to_sexp(Sexpistol.parse(string, parse_ruby_keyword_literals: true))
    end

    def to_sexp(ast_array)
      children = ast_array.map do |item|
        if  item.is_a?(Array)
          to_sexp(item)
        else
          item
        end
      end
      type = children.shift
      return type if type.is_a?(OrigenTesters::ATP::AST::Node)
      type = type.to_s.gsub('-', '_').to_sym
      OrigenTesters::ATP::AST::Node.new(type, children)
    end
  end
end
