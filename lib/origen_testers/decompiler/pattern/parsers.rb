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
