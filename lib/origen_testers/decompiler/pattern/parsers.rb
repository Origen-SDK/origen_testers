module OrigenTesters
  module Decompiler
    class Pattern
      module Parsers
        # We'll offload this to AST and Treetop to parse.
        # @abstract This requires the child to supply:
        #   A method parse_frontmatter(raw_frontmatter) which returns
        #   an AST node with the frontmatter parsed.
        #   There's no requirements on the frontmatter, as there's little resuse
        #   (in my experience) in frontmatter syntax and definitions.
        def _parse_frontmatter_
          parse_tree = parser.parse_frontmatter(raw_frontmatter)
          if parse_tree.is_a?(Hash)
            Origen.log.error('Parsing Error!')
            Origen.log.error("Unable to parse frontmatter of pattern #{source}")
            Origen.log.error("Error at: #{parse_tree[:line]}, #{parse_tree[:column]}")
            Origen.log.error('Message from the parser:')
            Origen.log.error(parse_tree[:message])
            Origen.log.error('---')

            fail(OrigenTesters::Decompiler::ParseError, "Could not parse the frontmatter of pattern #{source}")
          end
          @frontmatter = Frontmatter.new(ast: parse_tree, decompiled_pattern: self)
          @frontmatter
        end

        def print_unimplemented_error(m)
          Origen.app.fail!(message: "Error in Decompiler: Could not find suitable child-class method ##{m}. Cannot decompile pattern!")
        end

        # We'll offload this to AST and Treetop to parse.
        # @abstract This requires the child to supply:
        #   A method #parse_pinlist(raw_pinlist) which returns an AST node with
        #   the pinlist parsed.
        #
        #   The AST node should have a #pins method, which returns an array of
        #   the pin names (as Strings).
        #   Example:
        #     parse_pinlist('vector ($tset, tclk, tdi, tdo, tms)')
        #       #=> ['tclk', 'tdi', 'tdo', 'tms']
        def _parse_pinlist_
          parse_tree = parser.parse_pinlist(raw_pinlist)
          if parse_tree.is_a?(Hash)
            Origen.log.error('Parsing Error!')
            Origen.log.error("Unable to parse pinlist of pattern #{source}")
            Origen.log.error("Error at: #{parse_tree[:line] + section_indices[:pinlist_start]}, #{parse_tree[:column]}")
            Origen.log.error("(Pinlist begins at line #{section_indices[:pinlist_start]})")
            Origen.log.error('Message from the parser:')
            Origen.log.error(parse_tree[:message])
            Origen.log.error('---')

            fail(OrigenTesters::Decompiler::ParseError, "Could not parse the pinlist of pattern #{source}")
          end
          @pinlist = Pinlist.new(ast: parse_tree, decompiled_pattern: self)
          @pinlist
        end

        # We'll offload this to AST and Treetop to parse.
        # This will parse vectors line-by-line, so multi-line vectors will
        # need to take this into account.
        # @abstract This requires the child to supply:
        #   A method #parse_vector(raw_vector) which returns an AST node with
        #   the vector parsed.
        #
        #   This AST node should have the following:
        #     - operations
        #       - This should be an AST node with a repeat method.
        #       - All other methods here are platform independent, so no
        #         further checking is done.
        #     - timeset
        #       - This should return the timeset of the vector as a String.
        #     - pin states
        #       - This should return an array of strings, where each string
        #         corresponds to the pin state of a pin indicated by its offset
        #         into the pin header array.
        #     - comment
        #         The comment in this line. This can be either String,
        #         an Array of Strings (for multiline comments, if supported), or
        #         nil, if there is no comment.
        #     - line_comment
        #         A true/false value that indicates if this entire line is a comment.
        #         If true, operations, timeset, pin states, can be nil.
        def _parse_vector_(raw_vector, options = {})
          if self.is_a?(OrigenTesters::IGXLBasedTester::Pattern)
            if !(raw_vector =~ Regexp.new('^\s*//')).nil?
              # Match the comment start,ignoring any whitespace
              v_struct = Struct.new(:type, :comment) do
                def execute?; true; end
                
                def execute!(context); cc(comment); end
              end
              
              v = v_struct.new(:comment_block, raw_vector[raw_vector.index('//')+2..-1].strip)

#              v = {
#                type: :comment_block,
#                
#                # Preserve any extra comment characters. E.g.: '// comment //' should decompile to 'comment //'
#                comment: raw_vector[raw_vector.index('//')+2..-1].strip
#              }
            elsif !(raw_vector =~ Regexp.new('^\s*start_label')).nil?
              v_struct = Struct.new(:type, :start_label) do
                def execute?; false; end;
              end
              
              v = v_struct.new(:start_label, raw_vector[raw_vector.index('start_label')+11..-1].strip[0..-2])

#              v = {
#                type: :start_label,
#                
#                # Find the start_label text, then grab everything after that.
#                # Strip off the whitespace from either side, then finally remove the trailing ':' character
#                label: raw_vector[raw_vector.index('start_label')+11..-1].strip[0..-2],
#              }
            else
              # If we've not branched out to some other vector element, assume this is a vector
              v_struct = Struct.new(:type, :opcode, :opcode_arguments, :timeset, :pin_states, :comment, :repeat) do
                def execute?; true; end
                
                def execute!(context)
                  # Apply a timeset switch, if needed.
                  unless Origen.tester.timeset.name == timeset
                    Origen.tester.set_timeset(timeset)
                  end

                  # Apply the comment
                  unless comment.nil?
                    cc(comment)
                  end

                  # Apply the pin states
                  context.pinlist.each_with_index do |pin, i|
                    dut.pins(pin).vector_formatted_value = pin_states[i]
                  end

                  # Cycle the tester
                  repeat.cycles
                end
              end
              opcode_plus_args = raw_vector[0..raw_vector.index('>')].strip.split(/\s+/)
              timeset_plus_pins = raw_vector[(raw_vector.index('>')+1)..(raw_vector.index(';')-1)].strip.split(/\s+/)
              v = v_struct.new(:vector,
                opcode_plus_args[0],
                opcode_plus_args[1..-2],
                timeset_plus_pins[0],
                timeset_plus_pins[1..-1],
                begin
                  if raw_vector =~ Regexp.new('//')
                   raw_vector[raw_vector.index('//')+2..-1].strip
                  end
                end,
                begin
                  if opcode_plus_args[0] == 'repeat'
                    opcode_plus_args[1].to_i
                  else
                    1
                  end
                end
              )

#              v = {
#                type: :vector,
#              
#                opcode: raw_vector[0..raw_vector.index('>')].strip.split(/\s+/)[0],
#                opcode_arguments: raw_vector[0..raw_vector.index('>')].strip.split(/\s+/)[1..-2],
#                timeset: raw_vector[(raw_vector.index('>')+1)..(raw_vector.index(';')-1)].strip.split(/\s+/)[0],
#                pin_states: raw_vector[(raw_vector.index('>')+1)..(raw_vector.index(';')-1)].strip.split(/\s+/)[1..-1],
#                comment: begin
#                  if raw_vector =~ Regexp.new('//')
#                    raw_vector[raw_vector.index('//')+2..-1].strip
#                  end
#                end
#              }
              
#              if v[:opcode] == 'repeat'
#                v[:repeat] = v[:opcode_arguments][0].to_i
#              else
#                v[:repeat] = 1
#              end
              v
            end
            #puts v.to_s.green
            @current_vector = VectorBodyElement.new(ast: v, decompiled_pattern: self, **options)
            @current_vector
          else
            parse_tree = parser.parse_vector(raw_vector)
            if parse_tree.is_a?(Hash)
              Origen.log.error('Parsing Error!')
              Origen.log.error("Unable to parse vector body of pattern #{source}")
              Origen.log.error("(Vectors begins at line #{section_indices[:vectors_start]})")
              Origen.log.error('Parsing failed at:')
              Origen.log.error("  vector index: #{options[:vector_index]}")
              Origen.log.error("  line:         #{options[:line]}")
              Origen.log.error('Message from the parser:')
              Origen.log.error(parse_tree[:message])
              Origen.log.error('---')

              fail(OrigenTesters::Decompiler::ParseError, "Could not parse the vector body of pattern #{source}")
            end
            @current_vector = VectorBodyElement.new(ast: parse_tree, decompiled_pattern: self, **options)
            @current_vector
          end
        end
      end
    end
  end
end
