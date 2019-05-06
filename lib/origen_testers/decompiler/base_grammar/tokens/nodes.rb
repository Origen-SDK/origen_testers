module OrigenTesters
  module Decompiler
    module BaseGrammar
      module Tokens
        class NewlineDelimitedTextToken < Treetop::Runtime::SyntaxNode
        end

        class NewlineToken < Treetop::Runtime::SyntaxNode
        end

        class SpacingToken < Treetop::Runtime::SyntaxNode
        end

        class WordToken < Treetop::Runtime::SyntaxNode
        end

        class WhitespaceToken < Treetop::Runtime::SyntaxNode
        end

        class Base10Integer < Treetop::Runtime::SyntaxNode
        end
      end
    end
  end
end
