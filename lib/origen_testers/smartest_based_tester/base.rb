module OrigenTesters
  module SmartestBasedTester
    class Base
      include VectorBasedTester

      # Disable inline (end of vector) comments, enabled by default
      attr_accessor :inline_comments

      # Returns whether the tester has been configured to wrap top-level flow modules with an
      # enable or not.
      #
      # Returns nil if not.
      #
      # Returns :enabled if the enable is configured to be on by default, or :disabled if it is
      # configured to be off by default.
      attr_reader :add_flow_enable

      # Returns the value defined at target-level on if/how to make test names unique within a
      # flow, the default value is :signature
      attr_reader :unique_test_names

      # permit modification of minimum repeat count
      attr_accessor :min_repeat_loop
      alias_method :min_repeat_count, :min_repeat_loop
      alias_method :min_repeat_count=, :min_repeat_loop=

      # When set to true, all test flows will be generated with a corresponding testtable limits
      # file, rather than having the limits attached inline to the test suites
      attr_accessor :create_limits_file

      # Returns an array of strings that indicate which test modes will be included in limits files,
      # by default returns an empty array.
      # If no test modes have been specified then the limits file will simply be generated with no
      # test modes.
      attr_reader :limitfile_test_modes
      alias_method :limitsfile_test_modes, :limitfile_test_modes

      # When set to true, tests which are marked with continue: true will be forced to pass in
      # generated test program flows. Flow branching based on the test result will be handled via
      # some other means to give the same flow if the test 'fails', however the test will always
      # appear as if it passed for data logging purposes.
      #
      # Testers which do not implement this option will ignore it.
      attr_accessor :force_pass_on_continue

      # When set to true, tests will be set to delayed binning by default (overon = on) unless
      # delayed: false is supplied when defining the test
      attr_accessor :delayed_binning

      def initialize(options = {})
        @max_repeat_loop = 65_535
        @min_repeat_loop = 33
        @pat_extension = 'avc'
        @compress = true
        # @support_repeat_previous = true
        @match_entries = 10
        @name = 'v93k'
        @comment_char = '#'
        @level_period = true
        @inline_comments = true
        @overlay_style = :subroutine		# default to use subroutine for overlay
        @capture_style = :hram			# default to use hram for capture
        @overlay_subr = nil

        if options[:add_flow_enable]
          self.add_flow_enable = options[:add_flow_enable]
        end
        if options.key?(:unique_test_names)
          @unique_test_names = options[:unique_test_names]
        else
          @unique_test_names = :signature
        end
        if options.key?(:create_limits_file)
          @create_limits_file = options[:create_limits_file]
        else
          @create_limits_file = false
        end
        self.limitfile_test_modes = options[:limitfile_test_modes] || options[:limitsfile_test_modes]
        self.force_pass_on_continue = options[:force_pass_on_continue]
        self.delayed_binning = options[:delayed_binning]
      end

      # Set the test mode(s) that you want to see in the limits files, supply an array of mode names
      # to set multiple.
      def limitfile_test_modes=(val)
        @limitfile_test_modes = Array(val).map(&:to_s)
      end
      alias_method :limitsfile_test_modes, :limitfile_test_modes=

      # Set to :enabled to have all top-level flow modules wrapped by an enable flow variable
      # that is enabled by default (top-level flow has to disable modules it doesn't want).
      #
      # Set to :disabled to have the opposite, where the top-level flow has to enable all
      # modules.
      #
      # Note that the interface can override this setting for each flow during program generation.
      def add_flow_enable=(value)
        if value == :enable || value == :enabled
          @add_flow_enable = :enabled
        elsif value == :disable || value == :disabled
          @add_flow_enable = :disabled
        else
          fail "Unknown add_flow_enable value, #{value}, must be :enabled or :disabled"
        end
      end

      def cycle(options = {})
        # handle overlay if requested
        ovly_style = nil
        if options.key?(:overlay)
          ovly_style = options[:overlay][:overlay_style].nil? ? @overlay_style : options[:overlay][:overlay_style]
          overlay_str = options[:overlay][:overlay_str]

          # route the overlay request to the appropriate method
          case ovly_style
            when :subroutine, :default
              subroutine_overlay(overlay_str, options)
              ovly_style = :subroutine
            else
              ovly_style = overlay_style_warn(options[:overlay][:overlay_str], options)
          end # case ovly_style
        else
          @overlay_subr = nil
        end # of handle overlay

        options_overlay = options.delete(:overlay) if options.key?(:overlay)

        super(options) unless ovly_style == :subroutine

        unless options_overlay.nil?
          # stage = :body if ovly_style == :subroutine 		# always set stage back to body in case subr overlay was selected
        end
      end

      # Warn user of unsupported overlay style
      def overlay_style_warn(overlay_str, options)
        Origen.log.warn("Unrecognized overlay style :#{@overlay_style}, defaulting to subroutine")
        Origen.log.warn('Available overlay styles :subroutine')
        subroutine_overlay(overlay_str, options)
        @overlay_style = :subroutine		# Just give 1 warning
      end

      # Implement subroutine overlay, called by tester.cycle
      def subroutine_overlay(sub_name, options = {})
        if @overlay_subr != sub_name
          # unless last staged vector already has the subr call do the following
          i = -1
          i -= 1 until stage.bank[i].is_a?(OrigenTesters::Vector)
          if stage.bank[i].microcode !~ /#{sub_name}/

            # check for repeat on new last vector, unroll 1 if needed
            if stage.bank[i].repeat > 1
              v = OrigenTesters::Vector.new
              v.pin_vals = stage.bank[i].pin_vals
              v.timeset = stage.bank[i].timeset
              stage.bank[i].repeat -= 1
              stage.store(v)
              i = -1
            end

            # mark last vector as dont_compress
            stage.bank[i].dont_compress = true
            # insert subroutine call
            call_subroutine sub_name
          end # if microcode not placed
          @overlay_subr = sub_name
        end

        # stage = sub_name
      end # subroutine_overlay

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
      # Since the V93K store operates on a pin level (rather than vector level as on the J750)
      # equivalent functionality can also be achieved by setting the store attribute of the pin
      # itself prior to calling $tester.cycle.
      # However it is recommended to use the tester API to do the store if cross-compatiblity with
      # other platforms, such as the J750, is required.
      def store(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = { offset: 0
                  }.merge(options)
        pins = pins.flatten.compact
        if pins.empty?
          fail 'For the V93K you must supply the pins to store/capture'
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
          fail 'For the V93K you must supply the pins to store/capture'
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

      # Start a subroutine.
      #
      # Generates a global subroutine label. Global is used to adhere to the best practice of
      # containing all subroutines in dedicated patterns, e.g. global_subs.atp
      #
      # ==== Examples
      #     $tester.start_subroutine("wait_for_done")
      #     < generate your subroutine vectors here >
      #     $tester.end_subroutine
      def start_subroutine(name)
        local_subroutines << name.to_s.chomp unless local_subroutines.include?(name.to_s.chomp) || @inhibit_vectors
        # name += "_subr" unless name =~ /sub/
        Pattern.open name: name, call_startup_callbacks: false, subroutine: true
      end

      # Ends the current subroutine that was started with a previous call to start_subroutine
      def end_subroutine(_cond = false)
        Pattern.close call_shutdown_callbacks: false, subroutine: true
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

        code = "SQPG JSUB #{name};"
        if !options[:suppress_repeated_calls] ||
           last_object != code
          microcode code, offset: (options[:offset] * -1)
        end
      end

      # Handshake with the tester.
      #
      # ==== Examples
      #   $tester.handshake                   # Pass control to the tester for a measurement
      def handshake(options = {})
        options = {
        }.merge(options)
        Pattern.split(options)
      end

      # Do a frequency measure.
      #
      # ==== Examples
      #   $tester.freq_count($top.pin(:d_out))                 # Freq measure on pin "d_out"
      def freq_count(_pin, options = {})
        options = {
        }.merge(options)
        Pattern.split(options)
      end

      # Generates a match loop on up to two pins.
      #
      # This method is not really intended to be called directly, rather you should call
      # via Tester#wait e.g. $tester.wait(:match => true).
      #
      # The timeout should be provided in cycles, however when called via the wait method the
      # time-based helpers (time_in_us, etc) will be converted to cycles for you.
      # The following options are available to tailor the match loop behavior, defaults in
      # parenthesis:
      #
      # * :pin - The pin object to match on (*required*)
      # * :state - The pin state to match on, :low or :high (*required*)
      # * :check_for_fails (false) - Flushes the pipeline and checks for fails prior to the match (to allow binout of fails encountered before the match)
      # * :pin2 (nil) - Optionally supply a second pin to match on
      # * :state2 (nil) - State for the second pin (required if :pin2 is supplied)
      # * :force_fail_on_timeout (true) - Force a vector mis-compare if the match loop times out
      #
      # ==== Examples
      #   $tester.wait(:match => true, :time_in_us => 5000, :pin => $top.pin(:done), :state => :high)
      def match(pin, state, timeout_in_cycles, options = {})
        options = {
          check_for_fails:       false,
          pin2:                  false,
          state2:                false,
          global_loops:          false,
          generate_subroutine:   false,
          force_fail_on_timeout: true
        }.merge(options)

        # Ensure the match pins are don't care by default
        pin.dont_care
        options[:pin2].dont_care if options[:pin2]

        # Single condition loops are simple
        if !options[:pin2]
          # Use the counted match loop (rather than timed) which is recommended in the V93K docs for new applications
          # No pre-match failure handling is required here because the system will cleanly record failure info
          # for this kind of match loop
          cc "for the #{pin.name.upcase} pin to go #{state.to_s.upcase}"
          # Need to ensure at least 8 cycles with no compares before entering
          8.cycles
          number_of_loops = (timeout_in_cycles.to_f / 72).ceil
          # This seems to be a limit on the max MACT value, so account for longer times by expanding
          # the wait loop
          if number_of_loops > 262_144
            mrpt = ((timeout_in_cycles.to_f / 262_144) - 8).ceil
            mrpt = Math.sqrt(mrpt).ceil
            mrpt += (8 - (mrpt % 8)) # Keep to a multiple of 8, but round up to be safe
            number_of_loops = 262_144
          else
            mrpt = 8
          end
          microcode "SQPG MACT #{number_of_loops};"
          # Strobe the pin for the required state
          state == :low ? pin.expect_lo : pin.expect_hi
          # Always do 8 vectors here as this allows reconstruction of test results if multiple loops
          # are called in a pattern
          8.cycles
          pin.dont_care
          # Now do the wait loop, mrpt should always be a multiple of 8
          microcode "SQPG MRPT #{mrpt};"
          mrpt.times do
            cycle(dont_compress: true)
          end
          microcode 'SQPG PADDING;'
          8.cycles

        else

          # For two pins do something more like the J750 approach where branching based on miscompares is used
          # to keep the loop going
          cc "for the #{pin.name.upcase} pin to go #{state.to_s.upcase}"
          cc "or the #{options[:pin2].name.upcase} pin to go #{options[:state2].to_s.upcase}"

          if options[:check_for_fails]
            cc 'Return preserving existing errors if the pattern has already failed before arriving here'
            cycle(repeat: propagation_delay)
            microcode 'SQPG RETC 1 1;'
          end
          number_of_loops = (timeout_in_cycles.to_f / ((propagation_delay * 2) + 2)).ceil

          loop_vectors number_of_loops do
            # Check pin 1
            cc "Check if #{pin.name.upcase} is #{state.to_s.upcase} yet"
            state == :low ? pin.expect_lo! : pin.expect_hi!
            pin.dont_care
            cc 'Wait for failure to propagate'
            cycle(repeat: propagation_delay)
            cc 'Exit match loop if pin has matched (no error), otherwise clear error and remain in loop'
            microcode 'SQPG RETC 0 0;'

            # Check pin 2
            cc "Check if #{options[:pin2].name.upcase} is #{options[:state2].to_s.upcase} yet"
            options[:state2] == :low ? options[:pin2].expect_lo! : options[:pin2].expect_hi!
            options[:pin2].dont_care
            cc 'Wait for failure to propagate'
            cycle(repeat: propagation_delay)
            cc 'Exit match loop if pin has matched (no error), otherwise clear error and remain in loop'
            microcode 'SQPG RETC 0 0;'
          end

          if options[:force_fail_on_timeout]
            cc 'To get here something has gone wrong, strobe again to force a pattern failure'
            state == :low ? pin.expect_lo : pin.expect_hi
            options[:state2] == :low ? options[:pin2].expect_lo : options[:pin2].expect_hi if options[:pin2]
            cycle
            pin.dont_care
            options[:pin2].dont_care if options[:pin2]
          end
        end
      end

      # Returns the number of cycles to wait for any fails to propagate through the pipeline based on
      # the current timeset
      def propagation_delay
        # From 'Calculating the buffer cycles for JMPE and RETC (and match loops)' in SmarTest docs
        data_queue_buffer = (([105, 64 + ((125 + current_period_in_ns - 1) / current_period_in_ns).ceil].min + 3) * 8) + 72
        # Don't know how to calculate at runtime, hardcoding these to some default values for now
        number_of_sites = 128
        sclk_period = 40
        prop_delay_buffer = 195 + ((2 * number_of_sites + 3) * (sclk_period / 2))
        data_queue_buffer + prop_delay_buffer
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
        unless name.is_a?(String)
          name, number_of_loops, global = nil, name, number_of_loops
        end
        if number_of_loops > 1
          microcode "SQPG LBGN #{number_of_loops};"
          yield
          microcode 'SQPG LEND;'
        else
          yield
        end
      end
      alias_method :loop_vector, :loop_vectors

      # An internal method called by Origen to create the pattern header
      def pattern_header(options = {})
        options = {
        }.merge(options)
        pin_list = ordered_pins.map do |p|
          if Origen.app.pin_pattern_order.include?(p.id)
            # specified name overrides pin name
            if (p.is_a?(Origen::Pins::PinCollection)) || p.id != p.name
              p.id.to_s # groups or aliases can be lower case
            else
              p.id.to_s.upcase # pins must be uppercase
            end
          else
            if (p.is_a?(Origen::Pins::PinCollection)) || p.id != p.name
              p.name.to_s # groups or aliases can be lower case
            else
              p.name.to_s.upcase # pins must be uppercase
            end
          end
        end.join(' ')
        microcode "FORMAT #{pin_list};"
        if ordered_pins.size > 0
          max_pin_name_length = ordered_pins.map(&:name).max { |a, b| a.length <=> b.length }.length
          pin_widths = ordered_pins.map { |p| p.size - 1 }

          max_pin_name_length.times do |i|
            cc((' ' * 50) + ordered_pins.map.with_index { |p, x| ((p.name[i] || ' ') + ' ' * pin_widths[x]).gsub('_', '-') }.join(' '))
          end
        end
      end

      # An internal method called by Origen to generate the pattern footer
      def pattern_footer(options = {})
        options = {
          end_in_ka:      false
        }.merge(options)
        if options[:end_in_ka]
          Origen.log.warning '93K keep alive not yet implemented!'
          ss 'WARNING: 93K keep alive not yet implemented!'
        end
        microcode 'SQPG STOP;' unless options[:subroutine]
      end

      # Returns an array of subroutines called while generating the current pattern
      def called_subroutines
        @called_subroutines ||= []
      end

      # Returns an array of subroutines created by the current pattern
      def local_subroutines # :nodoc:
        @local_subroutines ||= []
      end

      # This is an internal method use by Origen which returns a fully formatted vector
      # You can override this if you wish to change the output formatting at vector level
      def format_vector(vec)
        timeset = vec.timeset ? "#{vec.timeset.name}" : ''
        pin_vals = vec.pin_vals ? "#{vec.pin_vals} " : ''
        if vec.repeat # > 1
          microcode = "R#{vec.repeat}"
        else
          microcode = vec.microcode ? vec.microcode : ''
        end

        if Origen.mode.simulation? || !inline_comments || $_testers_no_inline_comments
          comment = ''
        else

          header_comments = []
          repeat_comment = ''
          vec.comments.each_with_index do |comment, i|
            if comment =~ /^#/
              if comment =~ /^#(R\d+)$/
                repeat_comment = Regexp.last_match(1) + ' '
              # Throw away the ############# headers and footers
              elsif comment !~ /^# ####################/
                comment = comment.strip.sub(/^# (## )?/, '')
                if comment == ''
                  # Throw away empty lines at the start/end, but preserve them in the middle
                  unless header_comments.empty? || i == vec.comments.size - 1
                    header_comments << comment
                  end
                else
                  header_comments << comment
                end
              end
            end
          end

          if vec.pin_vals && ($_testers_enable_vector_comments || vector_comments)
            comment = "#{vec.number}:#{vec.cycle}"
            comment += ': ' if !header_comments.empty? || !vec.inline_comment.empty?
          else
            comment = ''
          end
          comment += header_comments.join("\cm") unless header_comments.empty?
          unless vec.inline_comment.empty?
            comment += "\cm" unless header_comments.empty?
            comment += "(#{vec.inline_comment})"
          end
          comment = "#{repeat_comment}#{comment}"
        end

        # Max comment length 250 at the end
        "#{microcode.ljust(25)}#{timeset.ljust(27)}#{pin_vals}# #{comment[0, 247]};"
      end

      # All vectors generated with the supplied block will have all pins set
      # to the repeat previous state. Any pins that are changed state within
      # the block will still update to the supplied value.
      # ==== Example
      #   # All pins except invoke will be assigned the repeat previous code
      #   # in the generated vector. On completion of the block they will
      #   # return to their previous state, except for invoke which will
      #   # retain the value assigned within the block.
      #   $tester.repeat_previous do
      #       $top.pin(:invoke).drive(1)
      #       $tester.cycle
      #   end
      def repeat_previous
        Origen.app.pin_map.each { |_id, pin| pin.repeat_previous = true }
        yield
        Origen.app.pin_map.each { |_id, pin| pin.repeat_previous = false }
      end

      def before_timeset_change(options = {})
        microcode "SQPG CTIM #{options[:new].name};" unless level_period?
      end
    end
  end
end
