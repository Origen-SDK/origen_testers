module OrigenTesters
  module StilBasedTester
    class Base
      include VectorBasedTester

      # When set to true generated patterns will only contain Pattern blocks, i.e. only vectors
      attr_accessor :pattern_only

      # Returns a new J750 instance, normally there would only ever be one of these
      # assigned to the global variable such as $tester by your target:
      #   $tester = J750.new
      def initialize(options = {})
        self.pattern_only = options.delete(:pattern_only)
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

      # An internal method called by Origen to create the pattern header
      def pattern_header(options = {})
        options = {
        }.merge(options)

        @pattern_name = options[:pattern]

        unless pattern_only
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

        if tester.ordered_pins_name.nil? && pattern_only
          Origen.log.warn "WARN: SigName must be defined for STIL format.  Use pin_pattern_order(*pins, name: <sigName>).  Defaulting to use 'ALL'"
        end
      end

      def set_timeset(t, period_in_ns = nil)
        super
        if pattern_only
          # Why does D10 not include this?
          # microcode "W #{t};"
        else
          @wavesets ||= []
          wave_number = nil
          @wavesets.each_with_index do |w, i|
            if w[:name] == timeset.name && w[:period] = timeset.period_in_ns
              wave_number = i
            end
          end
          unless wave_number
            lines = []
            ordered_pins.each do |pin|
              if pin.direction == :input || pin.direction == :io
                line = "#{pin.name} { 01 { "
                wave = pin.drive_wave if tester.timeset.dut_timeset
                (wave ? wave.evaluated_events : []).each do |t, v|
                  line << "'#{t}ns' "
                  # TODO: https://github.com/Origen-SDK/origen_testers/issues/196
                  # rubocop:disable Lint/DuplicateElsifCondition
                  if v == 0
                    line << 'D'
                  elsif v == 0
                    line << 'U'
                  else
                    line << 'D/U'
                  end
                  # rubocop:enable Lint/DuplicateElsifCondition
                  line << '; '
                end
                line << '}}'
                lines << line
              end
              if pin.direction == :output || pin.direction == :io
                line = "#{pin.name} { LHX { "
                wave = pin.compare_wave if tester.timeset.dut_timeset
                (wave ? wave.evaluated_events : []).each_with_index do |tv, i|
                  t, v = *tv
                  if i == 0 && t != 0
                    line << "'0ns' X; "
                  end
                  line << "'#{t}ns' "
                  # TODO: https://github.com/Origen-SDK/origen_testers/issues/196
                  # rubocop:disable Lint/DuplicateElsifCondition
                  if v == 0
                    line << 'L'
                  elsif v == 0
                    line << 'H'
                  else
                    line << 'L/H/X'
                  end
                  # rubocop:enable Lint/DuplicateElsifCondition
                  line << '; '
                end
                line << '}}'
                lines << line
              end
            end
            @wavesets << { name: timeset.name, period: timeset.period_in_ns, lines: lines }
            wave_number = @wavesets.size
          end
          microcode "W Waveset#{wave_number};"
        end
      end

      # Capture the pin data from a vector to the tester.
      #
      # This method uses the Digital Capture feature (Selective mode) of the V93000 to capture
      # the data from the given pins on the previous vector.
      # Note that is does not actually generate a new vector.
      #
      # Note also that any drive cycles on the target pins can also be captured, to avoid this
      # the wavetable should be set up like this to infer a 'D' (Don't Capture) on vectors where
      # the target pin is being used to drive data:
      #
      #   PINS nvm_fail
      #   0  d1:0  r1:D  0
      #   1  d1:1  r1:D  1
      #   2  r1:C  Capt
      #   3  r1:D  NoCapt
      #
      # Sometimes when generating vectors within a loop you may want to apply a capture
      # retrospectively to a previous vector, passing in an offset option will allow you
      # to do this.
      #
      # ==== Examples
      #   $tester.cycle                     # This is the vector you want to capture
      #   $tester.store :pin => pin(:fail)  # This applys the required opcode to the given pins
      #
      #   $tester.cycle                     # This one gets captured
      #   $tester.cycle
      #   $tester.cycle
      #   $tester.store(:pin => pin(:fail), :offset => -2) # Just realized I need to capture that earlier vector
      #
      #   # Capturing multiple pins:
      #   $tester.cycle
      #   $tester.store :pins => [pin(:fail), pin(:done)]
      #
      # Since the STIL store operates on a pin level (rather than vector level as on the J750)
      # equivalent functionality can also be achieved by setting the store attribute of the pin
      # itself prior to calling $tester.cycle.
      # However it is recommended to use the tester API to do the store if cross-compatibility with
      # other platforms, such as the J750, is required.
      def store(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = { offset: 0 }.merge(options)
        pins = pins.flatten.compact
        if pins.empty?
          fail 'For the STIL generation you must supply the pins to store/capture'
        end

        pins.each do |pin|
          pin.restore_state do
            pin.capture
            update_vector_pin_val pin, offset: options[:offset]
            last_vector(options[:offset]).dont_compress = true
            last_vector(options[:offset]).contains_capture = true
          end
        end
      end
      alias_method :capture, :store

      # Same as the store method, except that the capture will be applied to the next
      # vector to be generated.
      #
      # @example
      #   $tester.store_next_cycle
      #   $tester.cycle                # This is the vector that will be captured
      def store_next_cycle(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = {
        }.merge(options)
        pins = pins.flatten.compact
        if pins.empty?
          fail 'For STIL generation you must supply the pins to store/capture'
        end

        pins.each { |pin| pin.save; pin.capture }
        # Register this clean up function to be run after the next vector
        # is generated, cool or what!
        preset_next_vector do |vector|
          vector.contains_capture = true
          pins.each(&:restore)
        end
      end
      alias_method :store!, :store_next_cycle

      def match(pin, state, timeout_in_cycles, options = {})
        Origen.log.warning "Call to match loop on pin #{pin.id} is not supported by the STIL generator and has been ignored"
      end

      def match_block(timeout_in_cycles, options = {}, &block)
        Origen.log.warning 'Call to match loop block is not supported by the STIL generator and has been ignored'
      end

      # Add a loop to the pattern.
      #
      # Pass in the number of times to execute it, all vectors
      # generated by the given block will be captured in the loop.
      #
      # ==== Examples
      #   $tester.loop_vectors 3 do   # Do this 3 times...
      #       $tester.cycle
      #       some_other_method_to_generate_vectors
      #   end
      #
      # For compatibility with the J750 you can supply a name as the first argument
      # and that will simply be ignored when generated for the V93K tester...
      #
      #   $tester.loop_vectors "my_loop", 3 do   # Do this 3 times...
      #       $tester.cycle
      #       some_other_method_to_generate_vectors
      #   end
      def loop_vectors(name = nil, number_of_loops = 1, _global = false)
        # The name argument is present to maych J750 API, sort out the
        unless name.is_a?(String) || name.is_a?(Symbol)
          name, number_of_loops, global = 'loop', name, number_of_loops
        end
        if number_of_loops > 1
          @loop_counters ||= {}
          if @loop_counters[name]
            @loop_counters[name] += 1
          else
            @loop_counters[name] = 0
          end
          loop_name = @loop_counters[name] == 0 ? name : "#{name}_#{@loop_counters[name]}"
          loop_name = loop_name.symbolize
          microcode "#{loop_name}: Loop #{number_of_loops} {"
          yield
          microcode '}'
        else
          yield
        end
      end
      alias_method :loop_vector, :loop_vectors

      # An internal method called by Origen to generate the pattern footer
      def pattern_footer(options = {})
        cycle dont_compress: true     # one extra single vector before stop microcode
        microcode 'Stop;' unless options[:subroutine]
        microcode '}'
        @footer_done = true
      end

      # Returns an array of subroutines called while generating the current pattern
      def called_subroutines
        @called_subroutines ||= []
      end

      # Call a subroutine.
      #
      # This calls a subroutine immediately following previous vector, it does not
      # generate a new vector.
      #
      # Subroutines should always be called through this method as it ensures a running
      # log of called subroutines is maintained and which then gets output in the pattern
      # header to import the right dependencies.
      #
      # An offset option is available to make the call on earlier vectors.
      #
      # Repeated calls to the same subroutine will automatically be compressed unless
      # option :suppress_repeated_calls is supplied and set to false. This means that for
      # the common use case of calling a subroutine to implement an overlay the subroutine
      # can be called for every bit that has the overlay and the pattern will automatically
      # generate correctly.
      #
      # ==== Examples
      #   $tester.call_subroutine("mysub")
      #   $tester.call_subroutine("my_other_sub", :offset => -1)
      def call_subroutine(name, options = {})
        options = {
          offset:                  0,
          suppress_repeated_calls: true
        }.merge(options)
        called_subroutines << name.to_s.chomp unless called_subroutines.include?(name.to_s.chomp) || @inhibit_vectors

        code = "Call #{name};"
        if !options[:suppress_repeated_calls] ||
           last_object != code
          microcode code, offset: (options[:offset] * -1)
        end
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
    end
  end
end
