module OrigenTesters
  module Decompiler
    class Pattern
      module Parsers
        # @abstract This requires the child to supply:
        #   A method #parse_frontmatter(raw_frontmatter) which returns
        #   a node with the frontmatter parsed.
        def _parse_frontmatter_
          begin
            n = method_parse_frontmatter.call(raw_frontmatter: raw_frontmatter, context: self)
          rescue ParseError => e
            # If parsing threw a ParseError, the platform found the error.
            # Raise this as normal.
            raise(e)
          rescue Exception => e
            # Anything else, raise a parse error and provide the error raised
            # by parsing.
            m = "Error encountered while parsing the frontmatter: #{e.class}"
            Origen.log.error(m)
            Origen.log.error(e.message)
            Origen.log.error(e.backtrace.join("\n\t"))
            Origen.app!.fail(exception_class: ParseError, message: m)
          end

          # Seperate this out so that errors creating the frontmatter class
          # aren't confused with parsing errors.
          @frontmatter = Frontmatter.new(node: n, context: self)
        end

        # @abstract This requires the child to supply:
        #   A method #parse_pinlist(raw_pinlist) which returns a node with
        #   the pinlist parsed.
        #
        #   The node should have a #pins method, which returns an array of
        #   the pin names (as Strings).
        #   Example:
        #     parse_pinlist('vector ($tset, tclk, tdi, tdo, tms)')
        #       #=> ['tclk', 'tdi', 'tdo', 'tms']
        def _parse_pinlist_
          begin
            n = method_parse_pinlist.call(raw_pinlist: raw_pinlist, context: self)
          rescue ParseError => e
            # If parsing threw a ParseError, the platform found the error.
            # Raise this as normal.
            raise(e)
          rescue Exception => e
            # Anything else, raise a parse error and provide the error raised by parsing.
            m = "Error encountered while parsing the pinlist: #{e.class}"
            Origen.log.error(m)
            Origen.log.error(e.message)
            Origen.log.error(e.backtrace.join("\n\t"))
            Origen.app!.fail(exception_class: ParseError, message: m)
          end

          # Seperate this out so that errors creating the pinlist class
          # aren't confused with parsing errors.
          @pinlist = Pinlist.new(node: n, context: self)
        end

        # This will parse vectors line-by-line, so multi-line vectors will
        # need to take this into account.
        # @abstract This requires the child to supply:
        #   A method #parse_vector(raw_vector) which returns a node with
        #   the vector parsed.
        #
        #   This node should have the following:
        #     - type
        #     - platform_nodes
        #
        #   In the even the type is vector, it should also have:
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
        #     - comment
        #         A true/false value that indicates if this entire line is a comment.
        #         If true, operations, timeset, pin states, can be nil.
        #   If the type is something else (platform specifc, such as a 'starb label',for the J750),
        #     all contents can be in the 'platform_nodes'.
        def _parse_vector_(raw_vector, options = {})
          begin
            v = method_parse_vector.call(raw_vector: raw_vector, context: self, meta: (@vector_meta ||= {}))
          rescue ParseError => e
            # If parsing threw a ParseError, the platform found the error.
            # Raise this as normal.
            raise(e)
          rescue Exception => e
            # Anything else, raise a parse error and provide the error raised by parsing.
            m = "Error encountered while parsing the vector at index #{options[:vector_index]}: #{e.class}"
            Origen.log.error(m)
            Origen.log.error('While parsing:')
            Origen.log.error("  #{raw_vector}")
            Origen.log.error(e.message)
            Origen.log.error(e.backtrace.join("\n\t"))
            Origen.app!.fail(exception_class: ParseError, message: m)
          end

          # Seperate this out so that errors creating the vector body element class
          # aren't confused with parsing errors.
          @current_vector = VectorBodyElement.new(node: v, context: self, **options)
        end
      end
    end
  end
end
