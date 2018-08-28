require 'treetop'

module OrigenTesters
  # @note Can't call this just <code>SyntaxNode</code> since Treetop isn't namespaced to call its own node.
  # Will result in all nodes being Origen nodes, which isn't what we want.
  class Node < Treetop::Runtime::SyntaxNode
    #attr_reader :symbols

    def initialize(*args)
      super

      @symbols = begin
      end

      if respond_to?(:symbols)
        symbols.each do |s|
          define_singleton_method(s) do
            instance_variable_get("@#{s}".to_sym)
          end
        end
      end

      clean!
      symbolize
    end
    
    def execute
    	fail "Node #{self.class} cannot be executed!"
    end
    alias_method :generate, :execute
  end

	module IGXLBasedTester
		module Decompiler
			module Atp

			  class Atp < OrigenTesters::Node
			    def symbols
			      [:pattern_body]
			    end

			    def clean!
			    end

			    def symbolize
			      @pattern_body = elements.find { |e| e.is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::PatternBody) }
			      if @pattern_body.nil?
			        fail "Unable to symbolize ATP: Unable to find a pattern body!"
			      end
			    end
			  end

			  class Comment < Treetop::Runtime::SyntaxNode

			    attr_reader :comment
			    attr_reader :symbols

			    def initialize(*args)
			      super

			      @symbols = [:comment]
			      symbolize
			      clean!
			    end

			    def symbolize
			      @comment = self.elements[1].text_value
			    end

			    # Cleaing a comment is pretty straightfoward: remove the '//' and newline, and delete all the single_line_strings children to just get the text.
			    def clean!
			      self.elements.delete_at(0)
			      self.elements.delete_at(-1)
			      self.elements[0].elements.clear

			      @cleaned = true
			      self
			    end

			    def to_vector
			    end
			    
			    def execute
			    	pp comment do
			    	end
			    end
			  end

			  class StartLabel < OrigenTesters::Node
			    def clean!
			    end

			    def symbolize
			    end
			  end

			  class Label < OrigenTesters::Node
			    def clean!
			    end

			    def symbolize
			    end
			  end

			  class Vector < OrigenTesters::Node
			    def clean!
			      #opcode? spacing opcode_arguments? spacing? '>' spacing vector_timeset spacing (pin_state spacing)* ';' spacing? comment? spacing? newline
			      # A single vector has quite a bit going on, mostly due to there being several optional fields that may either by spacing or actual values.
			      # We'll go through these fields one-by-one and check what they are.
			      # Note that a standard SyntaxNode in place of an expected node means that those tokens were not available.
			      # E.g., instead of an empty Opcode code, we'll get an empty SyntaxNode.
			      # We'll leave some empty nodes in here to facilitate symbolizing. That is, we'll leave the Opcode, Opcode Arguments, and Comments, even if they are empty.
			      #   Symoblizing will know that empty nodes in those locations are empty values.
			      index = 0
			      puts text_value

			      # Opcode (Conditional)
			      unless elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::Opcode) || elements[index].is_a?(Treetop::Runtime::SyntaxNode)
			        fail "Failed to clean Vector: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::Opcode or Treetop::Runtime::SyntaxNode but received class #{elements[index].class}"
			      end
			      index += 1

			      # Spacing between opcode and the arguments
			      # Note: due to this coming up first, the spacing here will actually eat up the spacing between the opcode arguments and '>', if there's no opcode/arguments.
			      if elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean Vector: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::Spacing but received class #{elements[index].class}"
			      end

			      # Opcode Arguments (Conditional)
			      unless elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::OpcodeArguments) || elements[index].is_a?(Treetop::Runtime::SyntaxNode)
			        fail "Failed to clean Vector: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::OpcodeArguments or Treetop::Runtime::SyntaxNode but received class #{elements[index].class}"
			      end
			      index += 1

			      # Spacing between the opcode arguments and the '>' symbol (Conditional)
			      if elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken) || elements[index].is_a?(Treetop::Runtime::SyntaxNode)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean Vector: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::Spacing or Treetop::Runtime::SyntaxNode but received class #{elements[index].class}"
			      end
			      
			      # '>'
			      if elements[index].is_a?(Treetop::Runtime::SyntaxNode)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean Vector: expected element of class Treetop::Runtime::SyntaxNode but received class #{elements[index].class}"
			      end
			      
			      # Spacing between '>' and the timeset
			      if elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean Vector: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::Spacing but received class #{elements[index].class}"
			      end
			      
			      # Timeset
			      unless elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorTimeset)
			        fail "Failed to clean Vector: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorTimeset but received class #{elements[index].class}"
			      end
			      index += 1

			      # Spacing between the tiemset and the pin states
			      if elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean Vector: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken but received class #{elements[index].class}"
			      end

			      # The pin states
			      unless elements[index].is_a?(Treetop::Runtime::SyntaxNode)
			        fail "Failed to clean Vector: expected element of class Treetop::Runtime::SyntaxNode but received class #{elements[index].class}"
			      end
			      index += 1

			      # Spacing between the pin state and ';'
			     # if elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken)
			     #   elements.delete_at(index)
			     # else
			     #   fail "Failed to clean PatternBody: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken but received class #{elements[index].class}"
			     # end

			      # The ';' character
			      if elements[index].is_a?(Treetop::Runtime::SyntaxNode)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean Vector: expected element of class Treetop::Runtime::SyntaxNode but received class #{elements[index].class}"
			      end

			      # Spacing between ';' and the comment start (Conditional)
			      if elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken) || elements[0].is_a?(Treetop::Runtime::SyntaxNode)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean Vector: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::Spacing or Treetop::Runtime::SyntaxNode but received class #{elements[index].class}"
			      end

			      # Comment (Conditional)
			      # Note, any additionals spacing after the comment will be eaten by the comment itself
			      unless elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::Comment) || elements[index].is_a?(Treetop::Runtime::SyntaxNode)
			        fail "Failed to clean Vector: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::Comment or Treetop::Runtime::SyntaxNode but received class #{elements[index].class}"
			      end
			      index += 1

			      # Newline
			      if elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::NewlineToken)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean Vector: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::NewlineToken but received class #{elements[index].class}"
			      end

			    end

			    def symbols
			      [:repeat_count, :opcode, :opcode_arguments, :timeset, :pin_states, :comment]
			    end

			    def symbolize
			    	# For IGXL, 'repeat' is itself an opcode. But, Origen treats repeats differently to maintain consistency
			    	# across testers. We'll check if there is an opcode, but if that opcode is 'repeat', we'll mark it as
			    	# a 'repeat_count' instead of an opcode.
			    	
			    	opcode = elements[0].text_value
			    	opcode_arguments = elements[1].text_value
			    	
			    	if opcode == 'repeat'
							@repeat_count = opcode_arguments.to_i
							@opcode = ''
							@opcde_arguments = ''
			    	else
			    		@repeat_count = 1
			    		@opcode = opcode
			    		@opcode_arguments = opcode_arguments
			    	end
			    	
			    	@timeset = elements[2].text_value
			    	@pin_states = elements[3]
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

					def execute
						#tester.cycle(microcode: "#{opcode} #{opcode_arguments}", timeset: dut_timeset, repeat: repeat_count, pin_vals: pin_states.to_pin_vals)
						vector_pinlist = parent.parent.parent.vector_header.vector_pinlist
						
						# Match the pin states to the pinlist
						# Assume this is coming from Origen (for now) and that the pinlist order == pin states order
						vector_pinlist.pinlist.each_with_index do |pin_node, i|
							dut.pins(pin_node.elements[0].text_value).vector_formatted_value = pin_states.pins[i].text_value
						end
						
						repeat_count.cycles
					end

			  end

			  class PinStates < OrigenTesters::Node
			    def symbols
			      [:pin_states]
			    end

			    def clean!
			      # Due to the way Treetop treats the * character, we'll get an array of syntax nodes here,
			      # but each should be an array of size 2: PinState node followed by a SpacingToken
			      # We'll just get rid of the spacing.

			      elements.each do |e|
			        unless e.elements[0].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::PinState)
			          fail "Failed to clean PinStates: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::PinState but received class #{elements[index].class}"
			        end

			        if e.elements[1].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken)
			          e.elements.delete_at(1)
			        else
			          fail "Failed to clean PinStates: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken but received class #{elements[index].class}"
			        end
			      end
			    end

			    def symbolize
			      @pin_states = elements
			    end
			    
			    def pins
			    	elements.map { |e| e.elements.first }
			   	end
			    
			    def to_pin_vals
			    	pins.map { |p| p.pin_state }.join(' ')
			    end
			  end

			  #class Word < Treetop::Runtime::SyntaxNode
			  #end

			  class Opcode < OrigenTesters::Node
			    def symbols
			      [:opcode]
			    end

			    def clean!
			      elements.clear
			    end

			    def symbolize
			      @opcode = text_value
			    end
			  end

			  class OpcodeArguments < OrigenTesters::Node
			    def symbols
			      [:opcode_arguments]
			    end

			    def clean!
			      elements.clear
			    end

			    def symbolize
			      @opcode_arguments = text_value
			    end
			  end

			  class VectorTimeset < OrigenTesters::Node
			    def symbols
			      [:vector_timeset]
			    end

			    def clean!
			      elements.clear
			    end
			    
			    def symbolize
			      @vector_timeset = text_value
			    end

			    def timeset
			      vector_timeset
			    end
			  end

			  class VectorPin < OrigenTesters::Node
			    def symbols
			      [:vector_pin]
			    end

			    def clean!
			      elements.clear
			    end

			    def symbolize
			      @vector_pin = text_value
			    end

			    def pin
			      vector_pin
			    end
			  end

			  class VectorPinlist < OrigenTesters::Node
			    def symbols
			      [:vector_pinlist]
			    end

			    def clean!
			      # Treetop uses a syntax node as a * node, so we'll get a single SyntaxNode, but we'll get VectorPin nodes below that.
			      # Cleaning the vector pinlist is more a matter of cleaning the underlying syntax nodes

			      elements.each do |e|
			        # Each element of the VectorPinlist should be a comma, possibly followed by spacing, followed by the VectorPin, possibly followed by more spacing.
			        # We'll remove everything except the VectorPin
			        index = 0

			        # ',' literal
			        if e.elements[index].is_a?(Treetop::Runtime::SyntaxNode)
			          e.elements.delete_at(index)
			        else
			          fail "Failed to clean VectorPinlist: expected element of class Treetop::Runtime::SyntaxNode but received class #{e.elements[index].class}"
			        end

			        # SpacingToken (Conditional)
			        if e.elements[index].is_a?(Treetop::Runtime::SyntaxNode) || e.elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken)
			          e.elements.delete_at(index)
			        else
			          fail "Failed to clean VectorPinlist: expected element of class Treetop::Runtime::SyntaxNode or OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken but received class #{e.elements[index].class}"
			        end

			        # Vector Pin
			        unless e.elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorPin)
			          fail "Failed to clean VectorPinlist: expected element of class (OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorPin but received class #{e.elements[index].class}"
			        end
			        index += 1

			        # SpacingToken (Conditional)
			        if e.elements[index].is_a?(Treetop::Runtime::SyntaxNode) || e.elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken)
			          e.elements.delete_at(index)
			        else
			          fail "Failed to clean VectorPinlist: expected element of class Treetop::Runtime::SyntaxNode or OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken but received class #{e.elements[index].class}"
			        end
			      end
			    end

			    def symbolize
			      @vector_pinlist = elements
			    end

			    def pinlist
			      vector_pinlist
			    end
			  end

			  class PinState < OrigenTesters::Node
			    def symbols
			      [:pin_state]
			    end

			    def clean!
			      elements.clear
			    end

			    def symbolize
			      @pin_state = text_value
			    end
			  end

			  class LabelName < OrigenTesters::Node
			    def symbols
			      [:label_name]
			    end

			    def clean!
			      elements.clear
			    end

			    def symblize
			    end
			  end

			  class VectorHeader < OrigenTesters::Node
			    def symbols
			      [:vector_pinlist]
			    end

			    def clean!
			      # THe vector header consists of some boiler plate stuff followed by a listing of the pins, in the order that they will appear in the vectors.
			      # Cleaning this is really straightforward: just rmeove the first four nodes (boilerplate stuff) and the last few (more boilerplate stuff).
			      # The important thing is the VectorPinlist but it has its own clean method.
			      index = 0

			      # 'vector' literal
			      if elements[index].is_a?(Treetop::Runtime::SyntaxNode)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean VectorHeader: expected element of class Treetop::Runtime::SyntaxNode but received class #{elements[index].class}"
			      end

			      # A single space literal
			      if elements[index].is_a?(Treetop::Runtime::SyntaxNode)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean VectorHeader: expected element of class Treetop::Runtime::SyntaxNode but received class #{elements[index].class}"
			      end

			      # '(' literal
			      if elements[index].is_a?(Treetop::Runtime::SyntaxNode)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean VectorHeader: expected element of class Treetop::Runtime::SyntaxNode but received class #{elements[index].class}"
			      end

			      # '$tset' literal
			      if elements[index].is_a?(Treetop::Runtime::SyntaxNode)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean VectorHeader: expected element of class Treetop::Runtime::SyntaxNode but received class #{elements[index].class}"
			      end
			      
			      # The vector pinlist
			      unless elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorPinlist)
			        fail "Failed to clean VectorHeader: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorPinlist but received class #{elements[index].class}"
			      end
			      index += 1

			      # ')' literal
			      if elements[index].is_a?(Treetop::Runtime::SyntaxNode)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean VectorHeader: expected element of class Treetop::Runtime::SyntaxNode but received class #{elements[index].class}"
			      end

			      # Spacing (Conditional)
			      if elements[index].is_a?(Treetop::Runtime::SyntaxNode) || elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean VectorHeader: expected element of class Treetop::Runtime::SyntaxNode or OrigenTesters::IGXLBasedTester::Decompiler::Atp::SpacingToken but received class #{elements[index].class}"
			      end

			      # Newline
			      if elements[index].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::NewlineToken)
			        elements.delete_at(index)
			      else
			        fail "Failed to clean VectorHeader: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::NewlineToken but received class #{elements[index].class}"
			      end
			    end

			    def symbolize
			      @vector_pinlist = elements[0]
			    end
			  end

			  class PatternBody < OrigenTesters::Node
			    def symbols
			      [:vector_header, :vector_body]
			    end

			    def clean!
			      # The pattern body consists of a bunch of elements that themselves have clean! methods. So, we get off easy here: just throw away the
			      # boiler plate stuff and let the other elements deal with cleaning.
			      # We will check what we're throwing away, just to make sure we get what we expect from the grammar. Unexpected symbols here mean a bug
			      # in the grammar.

			      # Expect: vector_header
			      if elements[0].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorHeader)
			      else
			        fail "Failed to clean PatternBody: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorHeader but received class #{elements[0].class}"
			      end

			      # Expect: newline
			      if elements[1].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::NewlineToken)
			        # Throw this away, SHIFTING the remaining array elements
			        elements.delete_at(1)
			      else
			        fail "Failed to clean PatternBody: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::NewlineToken but received class #{elements[1].class}"
			      end

			      # Expect: vector_start
			      if elements[1].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorBodyStartToken)
			        # Throw this away, SHIFTING the remaining array elements
			        elements.delete_at(1)
			      else
			        fail "Failed to clean PatternBody: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorBodyStartToken but received class #{elements[1].class}"
			      end

			      # Expect: newline
			      if elements[1].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::NewlineToken)
			        # Throw this away, SHIFTING the remaining array elements
			        elements.delete_at(1)
			      else
			        fail "Failed to clean PatternBody: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::NewlineToken but received class #{elements[1].class}"
			      end

			      # Expect: vector_body
			      if elements[1].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorBody)
			      else
			        fail "Failed to clean PatternBody: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorBody but received class #{elements[1].class}"
			      end

			      # Expect: vector_end
			      if elements[-1].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorBodyEndToken)
			        # Throw this away, SHIFTING the remaining array elements
			        elements.delete_at(-1)
			      else
			        fail "Failed to clean PatternBody: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::VectorBodyEndToken but received class #{elements[-1].class}"
			      end

			      # The cleaned vector body should now just consists of a vector_header and a vector_body

			    end

			    def symbolize
			      @vector_header =  elements[0]
			      @vector_body = elements[1]
			    end
			  end

			  class VectorBody < OrigenTesters::Node
			    def symbols
			      [:vectors]
			    end

			    def clean!
			      # The first element in the vector body will be the start label, on a lime by itself.
			      # The last element will be a newline.
			      # In between, will be a combination of comments, vectors, and label, in any order.
			      
			      if elements[0].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::StartLabel)
			        elements.delete_at(0)
			      else
			        fail "Failed to clean VectornBody: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::StartLabel but received class #{elements[-1].class}"
			      end

			      if elements[-1].is_a?(OrigenTesters::IGXLBasedTester::Decompiler::Atp::NewlineToken)
			        elements.delete_at(-1)
			      else
			        fail "Failed to clean VectorBody: expected element of class OrigenTesters::IGXLBasedTester::Decompiler::Atp::NewlineToken but received class #{elements[1].class}"
			      end
			    end

			    def symbolize
			      @vectors = elements[0]
			    end
			  end

			  ### Tokens ###
			  # These are 'tokens' instead of 'literals' because they may also include various whitespace characters.
			  # Literally/Syntatically, these would not be equivalent, but sematically, they are, which eases the burden of cleaning and symbolizing.
			  
			  class SpacingToken < Treetop::Runtime::SyntaxNode
			  end

			  class NewlineToken < Treetop::Runtime::SyntaxNode
			  end

			  class VectorBodyStartToken < Treetop::Runtime::SyntaxNode
			  end

			  class VectorBodyEndToken < Treetop::Runtime::SyntaxNode
			  end

			end			
		end
	end
end


