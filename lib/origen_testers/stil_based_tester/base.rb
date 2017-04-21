module OrigenTesters
  module StilBasedTester
    class Base
      include VectorBasedTester

      # Returns a new J750 instance, normally there would only ever be one of these
      # assigned to the global variable such as $tester by your target:
      #   $tester = J750.new
      def initialize
        @max_repeat_loop = 65_535
        @min_repeat_loop = 2
        @pat_extension = 'stil'
        @compress = true

        # @support_repeat_previous = true
        @match_entries = 10
        @name = 'd10'
        @comment_char = '//'
        @level_period = true
        @inline_comments = true
        @header_done = false
        @footer_done = false
      end

      def stil_based?
        true
      end

      def store(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = { offset: 0
                  }.merge(options)
        last_vector(options[:offset]).contains_capture = true
      end

      # An internal method called by Origen to create the pattern header
      def pattern_header(options = {})
        options = {
        }.merge(options)

        @pattern_name = options[:pattern]

        microcode "Pattern \"#{@pattern_name}\" {"
        microcode "#{@pattern_name}:"
        @header_done = true

        if tester.ordered_pins_name.nil?
          Origen.log.warn "WARN: SigName must be defined for STIL format.  Use pin_pattern_order(*pins, name: <sigName>).  Defaulting to use 'ALL'"
        end
      end

      # An internal method called by Origen to generate the pattern footer
      def pattern_footer(options = {})
        cycle dont_compress: true     # one extra single vector before stop microcode
        microcode 'Stop;' unless options[:subroutine]
        microcode '}'
        @footer_done = true
      end

      # Subroutines not supported yet, print out an error to the output
      # file to alert the user that execution has hit code that is not
      # compatible.
      def call_subroutine(sub)
        microcode "Call_subroutine called to #{sub}"
      end

      def push_comment(msg)
        if @footer_done
          stage.store msg unless @inhibit_comments
        else
          stage.store "Ann {*#{msg}*}" unless @inhibit_comments
        end
      end

      # This is an internal method use by Origen which returns a fully formatted vector
      # You can override this if you wish to change the output formatting at vector level
      def format_vector(vec)
        timeset = vec.timeset ? "#{vec.timeset.name}" : ''
        pin_vals = vec.pin_vals ? "#{vec.pin_vals};".gsub(' ', '') : ''
        sig_name = tester.ordered_pins_name || 'ALL'
        if sig_name.nil?
          Origen.log.warn "WARN: SigName must be defined for STIL format.  Use pin_pattern_order(*pins, name: <sigName>).  Default to 'ALL'"
          sig_name = 'ALL'
        end
        if vec.repeat > 1
          microcode = "Loop #{vec.repeat} {\n"
        else
          microcode = vec.microcode ? vec.microcode : ''
        end
        if vec.pin_vals && ($_testers_enable_vector_comments || vector_comments)
          comment = "// V:#{vec.number} C:#{vec.cycle} #{vec.inline_comment}"
        else
          comment = vec.inline_comment.empty? ? '' : "Ann {*// #{vec.inline_comment}*}"
        end

        microcode_post = vec.repeat > 1 ? "\n}" : ''
        "#{microcode}  V { \"#{sig_name}\" = #{pin_vals} }#{comment}#{microcode_post}"
      end

      # Override this to force the formatting to match the v1 J750 model (easier diffs)
      def push_microcode(code) # :nodoc:
        stage.store(code.ljust(65) + ''.ljust(31))
      end
      alias_method :microcode, :push_microcode
    end
  end
end
