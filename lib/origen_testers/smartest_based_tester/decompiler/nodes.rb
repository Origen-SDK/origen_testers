module OrigenTesters
  module SmartestBasedTester
    module Decompiler
      module Avc
        include OrigenTesters::Decompiler::BaseGrammar

        class Avc < OrigenTesters::Decompiler::BaseGrammar::PatternModel
          CHECK = false
          CLEAN = false

          def initialize(*args)
            super
          end
        end

        class VectorBody < OrigenTesters::Decompiler::BaseGrammar::VectorBody
          CHECK = false
          CLEAN = false

          def symbolize
            @body = elements
            @first_vector = elements.find { |v| v.is_a?(Vector) }
            @first_timeset = @first_vector.timeset
          end
        end

        class VectorHeader < OrigenTesters::Decompiler::BaseGrammar::VectorHeader
          # The vector header for the AVC is pretty straightforward. Except for the PinNames, its all boilerplate stuff handled by the grammar
          # Check that we have PinNames at index 2.
          def check
            check_element(elements[2], OrigenTesters::Decompiler::BaseGrammar::PinNames)
          end

          def symbolize
            @pinlist = elements[2]
          end

          # Everythign except the pinlist is boilerplate. Clear everything except the PinNames node.
          def clean
            elements.reject! { |n| !n.is_a?(OrigenTesters::Decompiler::BaseGrammar::PinNames) }
          end
        end

        class Repeat < OrigenTesters::Decompiler::OrigenTestersNode
          def check
            check_element(elements[1], OrigenTesters::Decompiler::BaseGrammar::DecimalIntegerToken, index: 1)
          end

          def symbols
            [:count]
          end

          def symbolize
            @count = elements[1].text_value
          end

          def clean
            elements.clear
          end
        end

        class PatternBody < OrigenTesters::Decompiler::BaseGrammar::PatternBody
          CLEAN = false

          # Expect only two elements here: a vector header and vector body
          def check
            check_element(elements[0], VectorHeader, index: 0)
            check_element(elements[1], VectorBody, index: 1)
          end

          def symbolize
            @vector_header = elements[0]
            @vector_body = elements[1]
          end
        end

        class Vector < OrigenTesters::Decompiler::BaseGrammar::Vector
          CHECK = false
          # A vector should have the following format:
          #  Vector+Vector0 offset=1304, "...        X X X X # ;\n" (newline,repeat,timeset,pin_states,spacing1,spacing2):
          #    Repeat+Repeat0 offset=1304, "R65535" (decimal_integer):
          #    SpacingToken offset=1310, "                   " (spacing)
          #    Timeset+Timeset0 offset=1329, "tp0" (timeset)
          #    SpacingToken offset=1332, "...                    " (spacing)
          #    SyntaxNode+PinStates1 offset=1356, "X X X X" (pin_state):
          #    SpacingToken offset=1363, " " (spacing)
          #    Comment+Comment0 offset=1364, "# ;\n" (comment,newline,comment_start,newline_delimited_text):
          #    NewlineToken+Newline0 offset=1368, "" (text)

          # Cleaning for vectors is just getting rid of some of the filling: spacing and newlines. We'll hang on to the
          # important elements.
          def clean
            # Need to be careful since deleting at an index shift the other elements ups.
            elements.delete_at(1)
            elements.delete_at(2)
            elements.delete_at(3)
            elements.delete_at(4)
          end

          def symbolize
            @repeat = elements[0]
            @timeset = elements[2]
            @pin_states = elements[4]
            @comment = elements[6]
          end

          # AVCs are a bit strange, since anything after the last pni name from the header is a comment.
          # e.g., if the header is: TCLK TDI TDO
          # and the pin states are: X    X   X   X
          # the pin states will show 'X X X X', but the AVC will be compiled as 'X X X' and the last 'X' as a comment.
          # So, need to account for that here.
          # Since these both reside in the VectorModel, we can trace upwards to this guy's parent and query the number
          # of pins given, however, we need to do this after the tree has already been created.
          # def comment
          # end
        end

        # Encompasses a single firmware command and its arguments.
        class SequencerInstruction < OrigenTesters::Decompiler::OrigenTestersNode
          CHECK = false

          def symbols
            [:instr, :args]
          end

          def clean
            elements[0].elements.clear
            elements.delete_at(1) # spacing token. New index 1 are the arguments
            elements.delete_at(2) # ; literal
            elements.delete_at(2) # spacing
            elements.delete_at(2) # newline
          end

          def symbolize
            @instr = proc do
              elements[0].text_value
            end

            @args = proc do
              elements[1].args
            end
          end
        end

        # The sequencer args are a list, like the pin states or the pin names.
        # Just inherit from that..
        class SequencerArgs < OrigenTesters::Decompiler::OrigenTestersListNode
          def args
            @values.collect(&:text_value)
          end
        end
      end
    end
  end
end
