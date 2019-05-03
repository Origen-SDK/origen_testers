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
        @name = 'stil'
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

        unless @render_pattern_section_only
          microcode 'STIL 1.0;'

          microcode ''
          microcode 'Signals {'
          ordered_pins.each do |pin|
            line = ''
            line << "#{pin.name} "
            if pin.direction == :input
              line << 'In;'
            elsif pin.direction == :output
              line << 'Out;'
            else
              line << 'InOut;'
            end
            microcode "  #{line}"
          end
          microcode '}'

          microcode ''
          microcode 'SignalGroups {'
          line = "\"#{ordered_pins_name || 'ALL'}\" = '"
          ordered_pins.each_with_index do |pin, i|
            unless i == 0
              line << '+'
            end
            line << pin.name.to_s
          end
          microcode "  #{line}';"
          microcode '}'

          microcode ''
          microcode "Timing t_#{@pattern_name} {"
          (@wavesets || []).each_with_index do |w, i|
            microcode '' if i != 0
            microcode "  WaveformTable Waveset#{i + 1} {"
            microcode "    Period '#{w[:period]}ns';"
            microcode '    Waveforms {'
            w[:lines].each do |line|
              microcode "      #{line}"
            end
            microcode '    }'
            microcode '  }'
          end
          microcode '}'

          microcode ''
          microcode "PatternBurst b_#{@pattern_name} {"
          microcode "  PatList { #{@pattern_name}; }"
          microcode '}'

          microcode ''
          microcode "PatternExec e_#{@pattern_name} {"
          microcode "  Timing t_#{@pattern_name};"
          microcode "  PatternBurst b_#{@pattern_name};"
          microcode '}'
          microcode ''
        end

        microcode "Pattern \"#{@pattern_name}\" {"
        microcode "#{@pattern_name}:"
        @header_done = true

        if tester.ordered_pins_name.nil? && @render_pattern_section_only
          Origen.log.warn "WARN: SigName must be defined for STIL format.  Use pin_pattern_order(*pins, name: <sigName>).  Defaulting to use 'ALL'"
        end
      end

      def set_timeset(timeset, period_in_ns = nil)
        super
        if @render_pattern_section_only
          # Why does D10 not include this?
          # microcode "W #{timeset};"
        else
          @wavesets ||= []
          wave_number = nil
          @wavesets.each_with_index do |w, i|
            if w[:name] == @timeset.name && w[:period] = @timeset.period_in_ns
              wave_number = i
            end
          end
          unless wave_number
            lines = []
            ordered_pins.each do |pin|
              if pin.direction == :input || pin.direction == :io
                line = "#{pin.name} { 01 { "
                wave = pin.drive_wave
                (wave ? wave.evaluated_events : []).each do |t, v|
                  line << "'#{t}ns' "
                  if v == 0
                    line << 'D'
                  elsif v == 0
                    line << 'U'
                  else
                    line << 'D/U'
                  end
                  line << '; '
                end
                line << '}}'
                lines << line
              end
              if pin.direction == :output || pin.direction == :io
                line = "#{pin.name} { LHX { "
                wave = pin.compare_wave
                (wave ? wave.evaluated_events : []).each_with_index do |tv, i|
                  t, v = *tv
                  if i == 0 && t != 0
                    line << "'0ns' X; "
                  end
                  line << "'#{t}ns' "
                  if v == 0
                    line << 'L'
                  elsif v == 0
                    line << 'H'
                  else
                    line << 'L/H/X'
                  end
                  line << '; '
                end
                line << '}}'
                lines << line
              end
            end
            @wavesets << { name: @timeset.name, period: @timeset.period_in_ns, lines: lines }
            wave_number = @wavesets.size
          end
          microcode "W Waveset#{wave_number};"
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
