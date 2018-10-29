require 'treetop'
require 'origen_testers/decompiler/origen_testers_node'
require 'origen_testers/decompiler/base_nodes'

module OrigenTesters
  module IGXLBasedTester
    module Decompiler
      module Atp
        include OrigenTesters::Decompiler::BaseGrammar

        class Atp < OrigenTesters::Decompiler::BaseGrammar::PatternModel
          CHECK = false

          # Remove any whitespace between the pattern elements.
          def clean
            elements.delete_if { |n| n.is_a?(OrigenTesters::Decompiler::BaseGrammar::WhitespaceToken) }
          end

          def initialize(*args)
            super
          end

          def symbols
            syms = super
            syms += [:pattern_setup]
            syms
          end

          def opcode_mode
          end

          def symbolize
            super
            @pattern_setup = elements.collect { |e| e.is_a?(Import) || e.is_a?(VariableAssignment) }
          end
        end

        class Import < OrigenTesters::Decompiler::OrigenTestersNode
          CHECK = false

          # Import node structure:
          # SyntaxNode offset=756, "import"
          # SpacingToken offset=762, " " (spacing,spacing=)
          # WordToken offset=763, "tset" (text,text=)
          # SpacingToken offset=767, " " (spacing,spacing=)
          # WordToken offset=768, "tp0" (text,text=)
          # SyntaxNode offset=771, ";"
          # We can just save off the import type and import name, and clear all the elements.

          def symbols
            [:type, :name]
          end

          def symbolize
            @type = elements[2].text_value
            @name = elements[4].text_value
          end

          def clean
            elements.clear
          end
        end

        class VariableAssignment < OrigenTesters::Decompiler::OrigenTestersNode
          CHECK = false

          # Variable Assignment node structure:
          # WordToken offset=853, "svm_only_file" (text,text=)
          # SpacingToken offset=866, " " (spacing,spacing=)
          # SyntaxNode offset=867, "="
          # SpacingToken offset=868, " " (spacing,spacing=)
          # WordToken offset=869, "no" (text,text=)
          # SyntaxNode offset=871, ";"
          # Like the import node, we can just save off the variable and value fields and clear the elements.

          def symbols
            [:variable, :value]
          end

          def symbolize
            @variable = elements[0].text_value
            @value = elements[4].text_value
          end

          def clean
            elements.clear
          end
        end

        # PLACEHOLDER
        class StartLabel < OrigenTesters::Decompiler::OrigenTestersNode
          CLEAN = false
          CHECK = false
          SYMBOLIZE = false
        end

        # PLACEHOLDER
        class Label < OrigenTesters::Decompiler::OrigenTestersNode
          CLEAN = false
          CHECK = false
          SYMBOLIZE = false
        end

        class LabelName < OrigenTesters::Decompiler::OrigenTestersNode
          CLEAN = false
          CHECK = false
          SYMBOLIZE = false
        end

        class GlobalLabel < OrigenTesters::Decompiler::OrigenTestersNode
          CLEAN = false
          CHECK = false
          SYMBOLIZE = false
        end

        class Vector < OrigenTesters::Decompiler::BaseGrammar::Vector
          CHECK = false

          # ATP vector has a lot going on, but part of that is due to the optional items.
          # The vector is organized as:
          # Vector+Vector0 offset=3133, "...          X X X X ;\n" (newline,pin_states,vector_timeset,spacing1,spacing2,spacing3):
          # 0  Opcode offset=3133, "end_module" (opcode)
          # 1  SpacingToken offset=3143, "...                    " (spacing,spacing=)
          # 2  SyntaxNode offset=3198, ""
          # 3  SyntaxNode offset=3198, ""
          # 4  SyntaxNode offset=3198, ">"
          # 5  SpacingToken offset=3199, " " (spacing,spacing=)
          # 6  VectorTimeset offset=3200, "tp0" (vector_timeset)
          # 7  SpacingToken offset=3203, "...                    " (spacing,spacing=)
          # 8  PinStates+PinStates1 offset=3229, "X X X X" (values,values=):
          # 9  SpacingToken offset=3236, " " (spacing,spacing=)
          # 10  SyntaxNode offset=3237, ";"
          # 11  SyntaxNode offset=3238, ""
          # 12  SyntaxNode offset=3238, ""
          # 13  NewlineToken+Newline0 offset=3238, "\n" (text,text=)
          #  Most of this is filler, but note that the third item (index 2 above) is an optimal Op-code argument and the second-to-last node is an optimal comment.
          def clean
            delete_elements_at(1, 3, 4, 5, 7, 9, 10, 11, 13)
          end

          def symbols
            syms = super
            syms.delete(:repeat) # For ATP, the repeat is an opcode + argument
            syms += [:opcode, :opcode_args]
            syms
          end

          def repeat
            @repeat_count
          end

          def symbolize
            # For IGXL, 'repeat' is itself an opcode. But, Origen treats repeats differently to maintain consistency
            # across testers. We'll check if there is an opcode, but if that opcode is 'repeat', we'll mark it as
            # a 'repeat_count' instead of an opcode.

            opcode = elements[0].text_value
            opcode_args = elements[2].text_value

            if opcode == 'repeat'
              @repeat_count = opcode_args.to_i
              @opcode = false
              @opcode_args = false
            elsif opcode
              @repeat_count = 1
              @opcode = opcode
              @opcode_args = opcode_args || false
            else
              @repeat_count = 1
              @opcode = false
              @opcode_args = false
            end

            @timeset = proc do
              elements[2].text_value
            end
            @pin_states = elements[8]
            @comment = elements[12].text_value || false
          end
        end

        class Opcode < OrigenTesters::Decompiler::OrigenTestersNode
          CHECK = false

          def symbols
            [:opcode]
          end

          def clean
            elements.clear
          end

          def symbolize
            @opcode = text_value
          end
        end

        class OpcodeArguments < OrigenTesters::Decompiler::OrigenTestersNode
          CHECK = false

          def symbols
            [:opcode_arguments]
          end

          def clean
            elements.clear
          end

          def symbolize
            @opcode_arguments = text_value
          end
        end

        class VectorHeader < OrigenTesters::Decompiler::BaseGrammar::VectorHeader
          CHECK = false

          # 0. SyntaxNode offset=1241, "vector"
          # 1. SyntaxNode offset=1247, " "
          # 2. SyntaxNode offset=1248, "("
          # 3. SyntaxNode offset=1249, "$tset"
          # 4. SyntaxNode offset=1254, ", "
          # 5. PinNames+PinNames1 offset=1256, "tclk, tdi, tdo, tms" (pin_names,pin_names=):
          # 6. SyntaxNode offset=1275, ")"
          # 7. SpacingToken offset=1276, "...                    " (spacing,spacing=)
          # 8. NewlineToken+Newline0 offset=1337, "\n" (text,text=)
          def clean
            delete_elements_at(0, 1, 2, 3, 4, 6, 7, 8)
          end

          def symbolize
            @pinlist = elements[5]
          end
        end

        class PatternBody < OrigenTesters::Decompiler::BaseGrammar::PatternBody
          CHECK = false

          # 1. VectorHeader+VectorHeader0 offset=1241, "...                   \n" (pinlist,pinlist=,newline):
          # 2. NewlineToken+Newline0 offset=1338, "" (text,text=)
          # 3. VectorBodyStartToken+VectorBodyStart0 offset=1338, "...                   \n" (newline):
          # 4. NewlineToken+Newline0 offset=1435, "" (text,text=)
          # 5. VectorBody+VectorBody0 offset=1435, "...          X X X X ;\n" (body,first_vector,body=,first_vector=,first_timeset=,newline,start_label):
          # 6. VectorBodyEndToken+VectorBodyEnd0 offset=3239, "...                   \n" (newline):
          def clean
            delete_elements_at(1, 2, 3, 5)
          end

          def symbolize
            @vector_header =  elements[0]
            @vector_body = elements[4]
          end
        end

        class VectorBody < OrigenTesters::Decompiler::BaseGrammar::VectorBody
          def symbols
            syms = super
            syms << :start_label
          end

          # Not much to clean here. We'll just drop the newline at the end.
          def clean
            elements.delete_at(-1)
          end

          def symbolize
            @start_label = elements[0]
            @body = elements[1].elements
            @first_vector = body.find { |v| v.is_a?(Vector) }
            @first_timeset = first_vector.timeset
          end
        end

        class VectorBodyStartToken < Treetop::Runtime::SyntaxNode
        end

        class VectorBodyEndToken < Treetop::Runtime::SyntaxNode
        end
      end
    end
  end
end
