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

      # use flow variable grouping or not
      attr_accessor :flow_variable_grouping

      # Returns the SMT version, defaults to 7
      attr_reader :smt_version

      # permit modification of minimum repeat count
      attr_accessor :min_repeat_loop
      alias_method :min_repeat_count, :min_repeat_loop
      alias_method :min_repeat_count=, :min_repeat_loop=

      # Control literal flag definitions
      attr_accessor :literal_flags      # whether flags should be exactly as indicated
      attr_accessor :literal_enables    # whether enables should be exactly as indicated

      # permit option to generate multiport type patterns
      # and use multiport type code
      attr_accessor :multiport
      alias_method :multi_port, :multiport
      alias_method :multi_port=, :multiport=
      attr_accessor :multiport_prefix     # multiport burst name prefix
      attr_accessor :multiport_postfix     # multiport burst name postfix

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

      # Sets the package namespace that all generated test collateral should be placed under,
      # defaults to the application's namespace if not defined (SMT8 only)
      attr_writer :package_namespace

      attr_writer :spec_path, :seq_path

      # When set to true, the bins and softbins sheets from the limits spreadsheet will
      # be written out to a standalone (spreadsheet) file instead (SMT8 only)
      attr_accessor :separate_bins_file

      # When set to true (the default), patterns will be generated in ZIP format instead of ASCII
      # format (SMT8 only)
      attr_accessor :zip_patterns

      # When set to true (the default), parameters will be generated in the flow file regardless if the default is selected
      # (SMT8 only)
      attr_accessor :print_all_params

      # Whether the pattern execution stops when the match loop fails (stopOnFail) or continues after the REPEATEND statement (continueOnFail).
      # (SMT8 only)
      attr_reader :match_continue_on_fail

      # If the optional inverted keyword is added, the loop matches whenever a comparison fails
      # (SMT8 only)
      attr_reader :match_inverted

      # wait time (s or ms) instead of repeat count
      # (SMT8 only)
      attr_reader :max_wait_in_time

      # When set to true, the flow path will have insertion in the subdirectories
      # (SMT8 only)
      attr_reader :insertion_in_the_flow_path

      def initialize(options = {})
        options = {
          # whether to use multiport bursts or not, if so this indicates the name of the port to use
          multiport:         false,
          multiport_prefix:  false,
          multiport_postfix: false
        }.merge(options)

        @smt_version = options[:smt_version] || 7

        @match_continue_on_fail = options[:match_continue_on_fail]
        @match_inverted = options[:match_inverted]
        @max_wait_in_time = options[:max_wait_in_time]

        @separate_bins_file = options[:separate_bins_file] || false
        if options.key?(:zip_patterns)
          @zip_patterns = options.delete(:zip_patterns)
        else
          @zip_patterns = true
        end

        if smt8?
          require_relative 'smt8'
          extend SMT8
        else
          require_relative 'smt7'
          extend SMT7
        end

        @max_repeat_loop = 65_535
        @min_repeat_loop = 33
        if smt8?
          @pat_extension = 'pat'
          @program_comment_char = ['println', '//']
          @print_all_params = options[:print_all_params].nil? ? true : options[:print_all_params]
        else
          @pat_extension = 'avc'
          @program_comment_char = ['print_dl', '//']
        end
        @compress = true
        # @support_repeat_previous = true
        @match_entries = 10
        @name = 'v93k'
        @comment_char = '#'
        @level_period = true
        @inline_comments = true
        @multiport = options[:multiport]
        @multiport_prefix = options[:multiport_prefix]
        @multiport_postfix = options[:multiport_postfix]
        @overlay_style = :subroutine	# default to use subroutine for overlay
        @capture_style = :hram			# default to use hram for capture
        @overlay_subr = nil
        @overlay_history = {} # used to track labels, subroutines, digsrc pins used etc
        @insertion_in_the_flow_path = options[:insertion_in_the_flow_path] # add insertion for path to the flows

        if options[:add_flow_enable]
          self.add_flow_enable = options[:add_flow_enable]
        end
        if options.key?(:unique_test_names)
          @unique_test_names = options[:unique_test_names]
        else
          if smt8?
            @unique_test_names = nil
          else
            @unique_test_names = :signature
          end
        end
        if options.key?(:create_limits_file)
          @create_limits_file = options[:create_limits_file]
        else
          if smt8?
            @create_limits_file = true
          else
            @create_limits_file = false
          end
        end

        if options.key?(:flow_variable_grouping)
          @flow_variable_grouping = options[:flow_variable_grouping]
        end

        if options[:literal_flags]
          @literal_flags = true
        end
        if options[:literal_enables]
          @literal_enables = true
        end

        @package_namespace = options.delete(:package_namespace)
        @spec_path = options.delete(:spec_path)
        @seq_path = options.delete(:seq_path)
        self.limitfile_test_modes = options[:limitfile_test_modes] || options[:limitsfile_test_modes]
        self.force_pass_on_continue = options[:force_pass_on_continue]
        self.delayed_binning = options[:delayed_binning]
      end

      def disable_pattern_diffs
        smt8? && zip_patterns
      end

      # Returns the package namespace that all generated test collateral should be placed under,
      # defaults to the application's namespace if not defined
      def package_namespace
        @package_namespace || Origen.app.namespace
      end

      def spec_path
        @spec_path || 'specs'
      end

      def seq_path
        @seq_path || 'specs'
      end
      # Set the test mode(s) that you want to see in the limits files, supply an array of mode names
      # to set multiple.
      def limitfile_test_modes=(val)
        @limitfile_test_modes = Array(val).map(&:to_s)
      end
      alias_method :limitsfile_test_modes, :limitfile_test_modes=

      # return the multiport burst name
      # provide the name you want to obtain multiport for
      def multiport_name(patt_name)
        name = "#{patt_name}"
        if @multiport
          name = "#{@multiport_prefix}_#{name}" if @multiport_prefix
          name = "#{name}_#{@multiport_postfix}" if @multiport_postfix
          unless @multiport_prefix || @multiport_postfix
            name = "#{@multiport}_#{name}"
          end
        end
        name
      end

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
            when :label, :global_label
              options[:dont_compress] = true
              unless @overlay_history.key?(overlay_str)
                cc "#{overlay_str}"
                @overlay_history[overlay_str] = { is_label: true }
              end
            when :handshake
              if @delayed_handshake
                if @delayed_handshake != overlay_str
                  handshake
                  @delayed_handshake = overlay_str
                end
              else
                @delayed_handshake = overlay_str
              end
            else
              ovly_style = overlay_style_warn(options[:overlay][:overlay_str], options)
          end # case ovly_style
        else
          handshake if @delayed_handshake
          @delayed_handshake = nil
          @overlay_subr = nil
        end # of handle overlay

        options_overlay = options.delete(:overlay) if options.key?(:overlay)

        unless ovly_style == :subroutine || ovly_style == :handshake
          super(options)
        end

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
            unless @inhibit_vectors
              last_vector(options[:offset]).dont_compress = true
              last_vector(options[:offset]).contains_capture = true
            end
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
        ::Pattern.open name: name, call_startup_callbacks: false, subroutine: true
      end

      # Ends the current subroutine that was started with a previous call to start_subroutine
      def end_subroutine(_cond = false)
        ::Pattern.close call_shutdown_callbacks: false, subroutine: true
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
        ::Pattern.split(options)
      end

      # Do a frequency measure.
      #
      # ==== Examples
      #   $tester.freq_count($top.pin(:d_out))                 # Freq measure on pin "d_out"
      def freq_count(_pin, options = {})
        options = {
        }.merge(options)
        ::Pattern.split(options)
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
        if !options[:pin2]
          cc "for the #{pin.name.upcase} pin to go #{state.to_s.upcase}"
          match_block(timeout_in_cycles, options) do |match_or_conditions, fail_conditions|
            match_or_conditions.add do
              state == :low ? pin.expect_lo : pin.expect_hi
              cycle
              pin.dont_care
            end
          end
        else
          cc "for the #{pin.name.upcase} pin to go #{state.to_s.upcase}"
          cc "or the #{options[:pin2].name.upcase} pin to go #{options[:state2].to_s.upcase}"
          match_block(timeout_in_cycles, options) do |match_or_conditions, fail_conditions|
            match_or_conditions.add do
              state == :low ? pin.expect_lo : pin.expect_hi
              cycle
              pin.dont_care
            end
            match_or_conditions.add do
              options[:state2] == :low ? options[:pin2].expect_lo : options[:pin2].expect_hi
              cycle
              options[:pin2].dont_care
            end
            fail_conditions.add do
              cc 'To get here something has gone wrong, strobe again to force a pattern failure'
              state == :low ? pin.expect_lo : pin.expect_hi
              options[:state2] == :low ? options[:pin2].expect_lo : options[:pin2].expect_hi
              cycle
              pin.dont_care
              options[:pin2].dont_care
            end
          end
        end
      end

      def match_block(timeout_in_cycles, options = {}, &block)
        unless block_given?
          fail 'ERROR: block not passed to match_block!'
        end

        # take in the wait in time options for later usage
        if @max_wait_in_time
          @max_wait_in_time_options = options
        end

        # Create BlockArgs objects in order to receive multiple blocks
        match_conditions = Origen::Utility::BlockArgs.new
        fail_conditions = Origen::Utility::BlockArgs.new

        if block.arity > 0
          yield match_conditions, fail_conditions
        else
          match_conditions.add(&block)
        end

        # Generate a conventional match loop when there is only one match condition block
        if match_conditions.instance_variable_get(:@block_args).size == 1
          # Need to ensure at least 8 cycles with no compares before entering
          dut.pins.each do |name, pin|
            pin.save
            pin.dont_care if pin.comparing?
          end
          8.cycles
          dut.pins.each { |name, pin| pin.restore }

          # Placeholder, real number of loops required to implement the required timeout will be
          # concatenated onto the end later once the length of the match loop is known
          microcode 'SQPG MACT'
          match_microcode = stage.current_bank.last

          prematch_cycle_count = cycle_count
          match_conditions.each(&:call)

          match_loop_cycle_count = cycle_count - prematch_cycle_count

          # Pad the compare vectors out to a multiple of 8 per the ADV documentation
          until match_loop_cycle_count % 8 == 0
            cycle
            match_loop_cycle_count += 1
          end

          # Use 8 wait vectors by default to keep the overall number of cycles as a multiple of 8
          mrpt = 8

          number_of_loops = (timeout_in_cycles.to_f / (match_loop_cycle_count + mrpt)).ceil

          # There seems to be a limit on the max MACT value, so account for longer times by expanding
          # the wait loop
          while number_of_loops > 262_144
            mrpt = mrpt * 2 # Keep this as a multiple of 8
            number_of_loops = (timeout_in_cycles.to_f / (match_loop_cycle_count + mrpt)).ceil
          end

          match_microcode.concat(" #{number_of_loops};") unless @inhibit_vectors

          # for now forcing 8 vector for the pipe line cleaner - when using wait as time, might need to
          # investigate with using count
          # mrpt value might depends on the xMODE, need to find out how many xMODE there are in SM8
          if @max_wait_in_time
            mrpt = 8
          end

          # Now do the wait loop, mrpt should always be a multiple of 8
          microcode "SQPG MRPT #{mrpt};"

          # Should be no compares in the wait cycles
          dut.pins.each do |name, pin|
            pin.save
            pin.dont_care if pin.comparing?
          end
          mrpt.cycles
          dut.pins.each { |name, pin| pin.restore }

          # This is just used as a marker by the vector translator to indicate the end of the MRPT
          # vectors, it does not end up in the final pattern binary.
          # It is also used in a similar manner by Origen when generating SMT8 patterns.
          microcode 'SQPG PADDING;'

        # For multiple match conditions do something more like the J750 approach where branching based on
        # miscompares is used to keep the loop going
        else
          if options[:check_for_fails]
            cc 'Return preserving existing errors if the pattern has already failed before arriving here'
            cycle(repeat: propagation_delay)
            microcode 'SQPG RETC 1 1;'
          end

          loop_microcode = ''
          loop_cycles = 0
          loop_vectors 2 do
            loop_microcode = stage.current_bank.last
            preloop_cycle_count = cycle_count
            match_conditions.each do |condition|
              condition.call
              cc 'Wait for failure to propagate'
              cycle(repeat: propagation_delay)
              cc 'Exit match loop if pin has matched (no error), otherwise clear error and remain in loop'
              microcode 'SQPG RETC 0 0;'
            end
            loop_cycles = cycle_count - preloop_cycle_count
          end

          unless @inhibit_vectors
            number_of_loops = (timeout_in_cycles.to_f / loop_cycles).ceil

            loop_microcode.sub!('2', number_of_loops.to_s)
          end

          if options[:force_fail_on_timeout]
            fail_conditions.each(&:call)
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
