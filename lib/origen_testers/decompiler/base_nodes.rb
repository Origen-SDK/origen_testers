# Base nodes. These provide some starting points for a new platform to use in its decompiler
require 'origen_testers/decompiler/origen_testers_node'

module OrigenTesters
  module Decompiler
    module BaseGrammar
      # Represents a series of LineComments. During cleaning or execution, comment blocks can be ignored by querying
      #  the entire comment block (e.g., the Origen pattern header, or the 'ss' headers)
      # @note This is a 'comment block' instead of a 'block comment'. If the tester support block comments,
      # the comment block can be updated to include this and/or line comments.
      class CommentBlock < OrigenTestersNode
        CLEAN = false

        def symbols
          [:comments]
        end

        # Everything in the CommentBlock should be a comment item.
        def check
          elements.each_with_index { |e, i| check_element(e, Comment, index: i) }
        end

        def symbolize
          @comments = elements
        end

        # We'll execute the block as a whole and the tester will decide what to do.
        # For exmaple, most testers will simply print the comments line-by-line, but OrigenSim will join them together
        # to avoid glitches in the comment reg.
        def execute
          comments.each(&:execute)
        end
      end

      # Represents a single line comment. Comment blocks are just a collection of these until a non-line-comment
      # token is reached.
      class Comment < OrigenTestersNode
        # For a line comment we're expecting 3 nodes (in order):
        #  1. The comment symbol
        #  2. A newline-delmited string
        #  3. The newline itself.
        def check
          index = 0

          check_element(elements[index], CommentStartToken, index: index)
          index += 1

          check_element(elements[index], [NewlineDelimitedTextToken, SemicolonDelimitedTextToken], index: index)
          index += 1

          check_element(elements[index], NewlineToken, index: index)
          index += 1

          check_element_size(3)
        end

        # Cleaing a comment is pretty straightfoward:
        #  remove the comment_start token and tailing newline to get the newline delimited text.
        #  The newline_delimited_text should already be cleaned.
        def clean
          elements.clear
        end

        def symbols
          [:comment]
        end

        def symbolize
          @comment = elements[1].text_value
        end

        # Execute a single line comment with just a 'cc'
        def execute
          cc comment
        end
      end

      # A base PatternModel class. Inherit and expand, or override this class in the ATE-specific nodes.
      class PatternModel < OrigenTestersNode
        def symbols
          [:pattern_body, :vector_body, :first_vector, :pinlist]
        end

        # Provided this looks similar to the other base nodes, this symbolize may be a sufficient starting point
        # for setting the symbols above.
        # Other symbols will need to be symbolized themselves.
        def symbolize
          @pattern_body = elements.find { |e| e.is_a?(PatternBody) }
          @vector_body = @pattern_body.vector_body
          @first_vector = @pattern_body.vector_body.first_vector
          @pinlist = @pattern_body.vector_header.pinlist
        end

        # Assuming here that nothing has changed the pin pattern order.
        def pin_sizes
          @pin_sizes = first_vector.pin_states.elements.collect { |state| state.pin_state.size }
        end

        # Default execute is just to execute the pattern body.
        # The inheriting class can override/extend this as needed.
        def execute
          @vector_body.execute
        end
      end

      # A base VectorHeader class. Inherit and expand, or override this class in the ATE-specific nodes.
      class VectorHeader < OrigenTestersNode
        CHECK = false

        def symbols
          [:pinlist]
        end

        def pin_names
          @pinlist
        end
      end

      # A base VectorBody class. Inherit and expand, or override this class in the ATE-specific nodes.
      # The vector body encompasses comment_blocks, vectors, or anything else the ATE may have mixed in (e.g. firmware instructions for AVC)
      class VectorBody < OrigenTestersNode
        CHECK = false

        def symbols
          [:body, :first_vector, :first_timeset]
        end

        # A bit of misnomer since this can include non-vector objects (CommentBlocks, microcode/firmware commands for ATP/AVC, etc.)
        # For most patterns though, this will make sense.
        def vectors
          @body
        end

        # Locates the first vector and queries the timeset. This ONLY uses vectors. This must be overridden for ATEs
        # that contain timeset information differently.
        def first_timeset
          first_vector.timeset
        end

        # Executing the vector body is just a matter of calling execute on every element present.
        # Undefined execute blocks won't cause fails but will print warnings.
        # Empty execute blocks can be given to supress these -> the platform developer is consciously deciding to
        # skip/ignore these nodes.
        def execute
          # Begin execution by making sure we have some timeset set.
          if tester.timeset.nil?
            tester.set_timeset(first_timeset)
          end

          body.each do |b|
            if b.respond_to?(:execute)
              b.execute
            else
              Origen.log.warning "Vector body encountered element type #{b.class} during execution " \
                                 'but this element does not supported execution. No action taken!'
            end
          end
        end
      end

      class PatternBody < OrigenTestersNode
        def symbols
          [:vector_header, :vector_body]
        end
      end

      # A base vector class. Inherit and expand, or override this class in the ATE-specific nodes.
      class Vector < OrigenTestersNode
        def symbols
          [:repeat, :timeset, :pin_states, :comment]
        end

        # If the DUT exists, will attempt to retrieve the timeset object given in the decompiled pattern.
        # If not, just returns the timeset name.
        def dut_timeset
          @dut_timeset ||= begin
            if dut
              tset = dut.timesets[timeset]
              if tset.nil?
                fail "DUT object is defined as #{dut.name}, but could not locate a timeset #{timeset}"
              end
              tester.set_timeset(:intram, 40)
              tester.timeset
            else
              timeset
            end
          end
        end

        # The base for executing a vector only accounts for repeat, timeset, pin_states, and comments.
        # The vector will be executed by:
        #   1. Changing/setting the timeset, unless it is the same timeset.
        #   2. Applying the pin states.
        #   3. Applying the comment.
        #   4. Cycling the vector <repeat> number of times.
        # Any micro-code or firmware commands can also be handled by the ATE-specific implementation, but none are
        # handled here.
        def execute
          vector_pinlist = parent.parent.parent.vector_header.pinlist

          # Match the pin states to the pinlist
          # Assume this is coming from Origen (for now) and that the pinlist order == pin states order
          vector_pinlist.pins.each_with_index do |pin, i|
            dut.pins(pin).vector_formatted_value = pin_states.states[i]
          end
          repeat.cycles
        end
      end

      # These are 'tokens' instead of 'literals' because they may also include various whitespace characters.
      # Literally/Syntatically, these would not be equivalent, but sematically, they are, which eases the burden of cleaning and symbolizing.

      class SpacingToken < OrigenTestersNode
        CHECK = false

        def symbols
          [:spacing]
        end

        def clean
          elements.clear
        end

        def symbolize
          @spacing = text_value
        end
      end

      class DecimalIntegerToken < OrigenTestersNode
        CHECK = false

        def symbols
          [:number]
        end

        def clean
          elements.clear
        end

        def symbolize
          @number = text_value
        end

        def num
          @number
        end
      end

      class Timeset < OrigenTestersNode
        CHECK = false

        def symbols
          [:timeset]
        end

        def symbolize
          @timeset = text_value
        end

        def clean
          elements.clear
        end
      end

      class WordToken < OrigenTestersNode
        CHECK = false
        def symbols
          [:text]
        end

        def symbolize
          @text = text_value
        end

        def clean
          elements.clear
        end
      end

      class WhitespaceToken < OrigenTestersNode
        SYMBOLIZE = false
        CHECK = false

        def clean
          elements.clear
        end
      end

      class CommentStartToken < Treetop::Runtime::SyntaxNode
      end

      class NewlineToken < OrigenTestersNode
        CHECK = false

        def symbols
          [:text]
        end

        def symbolize
          @text = text_value
        end

        def clean
          elements.clear
        end
      end

      class NewlineDelimitedTextToken < OrigenTestersNode
        def symbols
          [:text]
        end

        # Everything in this should just be a syntax node
        def check
          elements.each_with_index { |e, i| check_element(elements[i], Treetop::Runtime::SyntaxNode, index: i) }
        end

        def symbolize
          @text = text_value
        end

        def clean
          elements.clear
        end
      end

      class SemicolonDelimitedTextToken < OrigenTestersNode
        def symbols
          [:text]
        end

        # Everything in this should just be a syntax node
        def check
          elements.each_with_index { |e, i| check_element(elements[i], Treetop::Runtime::SyntaxNode, index: i) }
        end

        def symbolize
          @text = text_value
        end

        def clean
          elements.clear
        end
      end

      class PinNameSeparator < Treetop::Runtime::SyntaxNode
      end

      class PinStateSeparator < Treetop::Runtime::SyntaxNode
      end

      class PinNames < OrigenTestersListNode
        # CHECK = false
        CLEAN = false
        # SYMBOLIZE = false

        def symbols
          [:pin_names]
        end

        def pins
          @pin_names
        end

        def num_pins
          @pin_names.size
        end

        # Expect only two elements: a PinName followed by a syntax node.
        # The syntax node should a list of syntax nodes for each additionl pin name given. The nested syntax node
        # will be a PinSeparator followed by the PinName.
        # e.g. (from approved/delay.avc):
        #  PinNames+PinNames1 offset=821, "TCLK TDI TDO TMS" (pin_name):
        #    PinName offset=821, "TCLK":
        #    SyntaxNode offset=825, " TDI TDO TMS":
        #      SyntaxNode+PinNames0 offset=825, " TDI" (pin_name_separator,pin_name):
        #        PinNameSeparator offset=825, " "
        #        PinName offset=826, "TDI":
        #      SyntaxNode+PinNames0 offset=829, " TDO" (pin_name_separator,pin_name):
        #        PinNameSeparator offset=829, " "
        #        PinName offset=830, "TDO":
        #      SyntaxNode+PinNames0 offset=833, " TMS" (pin_name_separator,pin_name):
        #        PinNameSeparator offset=833, " "
        #        PinName offset=834, "TMS":
        def check
          index = 0
          check_element(elements[index], PinName, index: index)
          index += 1

          check_element(elements[index], Treetop::Runtime::SyntaxNode, index: index)
          index += 1

          elements[1].elements.each_with_index do |e, i|
            check_element(e.elements[0], PinNameSeparator)
            check_element(e.elements[1], PinName)
          end

          check_element_size(2)
        end

        def symbolize
          @pin_names = []
          @pin_names << elements[0].text_value
          @pin_names += elements[1].elements.collect { |e| e.elements[1].text_value } unless elements[1].empty?

          # Save off the number of the pins and the size of each pin.
          OrigenTesters::Decompiler::BaseGrammar::BaseParser.metadata[:pin_names] = self
        end
      end

      class PinName < OrigenTestersNode
        CHECK = false

        def symbols
          [:pin_name]
        end

        def symbolize
          @pin_name = text_value
        end

        def clean
          elements.clear
        end
      end

      # The pin states are very close to the pin names: a list of items delimited by a separator.
      class PinStates < OrigenTestersListNode
        # CLEAN = false

        # This looks very similar to the PinNames above. We'll handle checking this in the same way.
        # example (from delay.avc):
        #   SyntaxNode+PinStates1 offset=1149, "X X X X" (pin_state):
        #      PinState offset=1149, "X":
        #      SyntaxNode offset=1150, " X X X":
        #        SyntaxNode+PinStates0 offset=1150, " X" (pin_state,pin_state_separator):
        #          PinStateSeparator offset=1150, " "
        #          PinState offset=1151, "X":
        #        SyntaxNode+PinStates0 offset=1152, " X" (pin_state,pin_state_separator):
        #          PinStateSeparator offset=1152, " "
        #          PinState offset=1153, "X":
        #        SyntaxNode+PinStates0 offset=1154, " X" (pin_state,pin_state_separator):
        #          PinStateSeparator offset=1154, " "
        #          PinState offset=1155, "X":
        # def check
        #  Origen.log.error "DO THIS"
        # end

        # def symbols
        #  [:pin_states]
        # end

        def states
          @values.collect(&:text_value)
        end

        def num_pins
          @values.size
        end
        alias_method :num_states, :num_pins

        # def symbolize
        #  @pin_states = []
        #  @pin_states << elements[0].text_value
        #  @pin_states += elements[1].elements.collect { |e| e.elements[1].text_value } unless elements[1].empty?
        # end

        # Cleaning the PinStates is just a matter of shifting all of the pin states in the (pin_name separator) to the same level
        # def clean
        #  nested_pin_states = elements[1].elements.collect { |e|
        #  elements.delete_at(1)
        #  elements += nested_pin_states
        # end
      end

      class PinState < OrigenTestersNode
        CHECK = false

        def symbols
          [:pin_state]
        end

        def symbolize
          @pin_state = text_value
        end

        def clean
          elements.clear
        end
      end
    end
  end
end
