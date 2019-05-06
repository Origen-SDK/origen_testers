module OrigenTesters
  module Decompiler
    module BaseGrammar
      module VectorBased
        class Frontmatter < Treetop::Runtime::SyntaxNode
          def to_ast
            n :frontmatter, *elements_to_ast
          end
        end

        class CommentStartToken < Treetop::Runtime::SyntaxNode
        end

        class CommentStart < Treetop::Runtime::SyntaxNode
        end

        class CommentBlock < Treetop::Runtime::SyntaxNode
        end

        class Comment < Treetop::Runtime::SyntaxNode
        end

        class Pinlist < Treetop::Runtime::SyntaxNode
          def to_ast
            n(:pinlist, *elements_to_ast)
          end
        end

        class PinNames < Treetop::Runtime::SyntaxNode
          def to_ast
            n(:pin_names, *elements_to_ast)
          end
        end

        class PinName < Treetop::Runtime::SyntaxNode
          def to_ast
            n(:pin_name, text_value)
          end
        end

        class PinNameSeparator < Treetop::Runtime::SyntaxNode
        end

        class PinStateSeparator < Treetop::Runtime::SyntaxNode
        end

        class PinStates < Treetop::Runtime::SyntaxNode
          def to_ast
            n(:pin_states, *elements_to_ast)
          end
        end

        class PinState < Treetop::Runtime::SyntaxNode
          def to_ast
            n(:pin_state, text_value)
          end
        end

        class Timeset < Treetop::Runtime::SyntaxNode
          def to_ast
            n(:timeset, text_value)
          end
        end
      end
    end
  end
end
