module OrigenTesters
  module IGXLBasedTester
    # This is the base class of all IGXL-based testers
    class Base
      include VectorBasedTester

      attr_accessor :software_version
      attr_accessor :pattern_compiler_pinmap
      attr_accessor :memory_test_en

      # NOTE: DO NOT USE THIS CLASS DIRECTLY ONLY USED AS PARENT FOR
      # DESIRED TESTER CLASS

      # Returns a new IGXLBasedTester instance, normally there would only ever be one of these
      # assigned to the global variable such as $tester by your target.
      def initialize
        @unique_counter = 0
        @counter_lsb_bits = 0
        @counter_msb_bits = 0
        @max_repeat_loop = 65_535 # 16 bits
        @min_repeat_loop = 2
        @pat_extension = 'atp'
        @active_loads = true
        @pipeline_depth = 34
        @software_version = ''
        @compress = true
        @support_repeat_previous = true
        @match_entries = 10
        @name = ''
        @program_comment_char = ['logprint', "'"]
        @opcode_mode = :extended
        @flags = %w(cpuA cpuB cpuC cpuD)
        @microcode = {}
        @microcode[:enable] = 'enable'
        @microcode[:set_flag] = 'set_cpu'
        @microcode[:mask_vector] = 'ign ifc icc'

        @mask_vector = false   # sticky option to mask all subsequent vectors

        @min_pattern_vectors = 0  # no minimum

        @memory_test_en = false  # memory test enabled (for all patterns?)
      end

      def assign_dc_instr_pins(dc_pins)
        @dc_pins = dc_pins
      end

      def get_dc_instr_pins
        @dc_pins
      end

      def flows
        parser.flows
      end

      # Main accessor to all content parsed from existing test program sheets found in the
      # supplied directory or in Origen.config.test_program_output_directory
      def parser(prog_dir = Origen.config.test_program_output_directory)
        unless prog_dir
          fail 'You must supply the directory containing the test program sheets, or define it via Origen.config.test_program_output_directory'
        end
        @parser ||= IGXLBasedTester::Parser.new
        @parsed_dir ||= false
        if @parsed_dir != prog_dir
          @parser.parse(prog_dir)
          @parsed_dir = prog_dir
        end
        @parser
      end

      # Capture a vector to the tester HRAM.
      #
      # This method applies a store vector (stv) opcode to the previous vector, note that is does
      # not actually generate a new vector.
      #
      # Sometimes when generating vectors within a loop you may want to apply a stv opcode
      # retrospectively to a previous vector, passing in an offset option will allow you
      # to do this.
      #
      # On J750 the pins argument is ignored since the tester only supports whole vector capture.
      #
      # @example
      #   $tester.cycle                # This is the vector you want to capture
      #   $tester.store                # This applies the STV opcode
      #
      #   $tester.cycle                # This one gets stored
      #   $tester.cycle
      #   $tester.cycle
      #   $tester.store(:offset => -2) # Just realized I need to capture that earlier vector
      def store(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = { offset: 0
                  }.merge(options)
        update_vector microcode: 'stv', offset: options[:offset]
      end
      alias_method :to_hram, :store
      alias_method :capture, :store

      # Capture the next vector generated to HRAM
      #
      # This method applies a store vector (stv) opcode to the next vector to be generated,
      # note that is does not actually generate a new vector.
      #
      # On J750 the pins argument is ignored since the tester only supports whole vector capture.
      #
      # @example
      #   $tester.store_next_cycle
      #   $tester.cycle                # This is the vector that will be captured
      def store_next_cycle(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = {
        }.merge(options)
        preset_next_vector microcode: 'stv'
      end
      alias_method :store!, :store_next_cycle

      # Call a subroutine.
      #
      # This method applies a call subroutine opcode to the previous vector, it does not
      # generate a new vector.
      #
      # Subroutines should always be called through this method as it ensures a running
      # log of called subroutines is maintained and which then gets output in the pattern
      # header to import the right dependencies.
      #
      # An offset option is available to make the call on earlier vectors.
      #
      # ==== Examples
      #   $tester.call_subroutine("mysub")
      #   $tester.call_subroutine("my_other_sub", :offset => -1)
      def call_subroutine(name, options = {})
        options = {
          offset: 0
        }.merge(options)
        called_subroutines << name.to_s.chomp unless called_subroutines.include?(name.to_s.chomp) || @inhibit_vectors
        update_vector microcode: "call #{name}", offset: options[:offset]
      end

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
        microcode "global subr #{name}:"
      end

      # End a subroutine.
      #
      # Generates a return opcode on the last vector.
      #
      # ==== Examples
      #     $tester.start_subroutine("wait_for_done")
      #     < generate your subroutine vectors here >
      #     $tester.end_subroutine
      # cond: whether return is conditional on a flag (to permit to mix subrs together)
      def end_subroutine(cond = false)
        if cond
          update_vector microcode: 'if (flag) return'
        else
          update_vector microcode: 'return'
        end
      end

      # Do a frequency measure.
      #
      # Write the necessary micro code to do a frequency measure on the given pin,
      # optionally supply a read code to pass information to the tester.
      #
      # ==== Examples
      #   $tester.freq_count($top.pin(:d_out))                 # Freq measure on pin "d_out"
      #   $tester.freq_count($top.pin(:d_out):readcode => 10)
      def freq_count(pin, options = {})
        options = { readcode: false
                  }.merge(options)

        set_code(options[:readcode]) if options[:readcode]
        cycle(microcode: "#{@microcode[:set_flag]} (cpuA)")
        cycle(microcode: "#{@microcode[:set_flag]} (cpuA)")
        cycle(microcode: "#{@microcode[:set_flag]} (cpuB)")
        cycle(microcode: "#{@microcode[:set_flag]} (cpuC)")
        cycle(microcode: 'freq_loop_1:')
        cycle(microcode: 'if (cpuA) jump freq_loop_1')
        pin.drive_lo
        delay(2000)
        pin.dont_care
        cycle(microcode: "freq_loop_2: #{@microcode[:enable]} (#{@flags[1]})")
        cycle(microcode: 'if (flag) jump freq_loop_2')
        cycle(microcode: "#{@microcode[:enable]} (#{@flags[2]})")
        cycle(microcode: 'if (flag) jump freq_loop_1')
      end

      # * J750 Specific *
      #
      # Generates a single MTO opcode line for J750
      #
      # Codes implemented: xa load_preset, xa inc, ya load_preset, ya inc, stv_m0, stv_m1, stv_c<br>
      def memory_test(options = {})
        options = {
          gen_vector:          true,                 # Default generate vector not just MTO opcode
          init_counter_x:      false,            # initialize counter X
          inc_counter_x:       false,             # increment counter X
          init_counter_y:      false,            # initialize counter X
          inc_counter_y:       false,             # increment counter X
          capture_vector:      false,            # capture vector to memory using all mem types
          capture_vector_mem0: false,       # capture vector to memory type 0, here for J750 will be stv_m0
          capture_vector_mem1: false,       # capture vector to memory type 1, here for J750 will be stv_m1
          capture_vector_mem2: false,       # capture vector to memory type 2, here for J750 will be stv_c
          pin:                 false,                       # pin on which to drive or expect data, pass pin object here!
          pin_data:            false,                  # pin data (:none, :drive, :expect)
        }.merge(options)

        mto_opcode = ''

        if options[:init_counter_x]
          mto_opcode += ' xa load_preset'
        end
        if options[:inc_counter_x]
          mto_opcode += ' xa inc'
        end
        if options[:init_counter_y]
          mto_opcode += ' ya load_preset'
        end
        if options[:inc_counter_y]
          mto_opcode += ' ya inc'
        end
        if options[:capture_vector]
          mto_opcode += ' stv_m0 stv_m1 stv_c'
        end
        if options[:capture_vector_mem0]
          mto_opcode += ' stv_m0'
        end
        if options[:capture_vector_mem1]
          mto_opcode += ' stv_m1'
        end
        if options[:capture_vector_mem2]
          mto_opcode += ' stv_c'
        end

        unless mto_opcode.eql?('')
          mto_opcode = '(mto:' + mto_opcode + ')'
        end

        if options[:gen_vector]
          if options[:pin]
            case options[:pin_data]
              when :drive
                # store current pin state
                cur_pin_state = options[:pin].state.to_sym
                options[:pin].drive_mem
              when :expect
                # store current pin state
                cur_pin_state = options[:pin].state.to_sym
                options[:pin].expect_mem
            end
          end
          cycle(microcode: "#{mto_opcode}")
          if options[:pin]
            # restore previous pin state
            case options[:pin_data]
              when :drive
                options[:pin].state = cur_pin_state
              when :expect
                options[:pin].state = cur_pin_state
            end
          end
        else
          microcode "#{mto_opcode}"
        end
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
      # * :pin - The pin object to match on (*required*)
      # * :state - The pin state to match on, :low or :high (*required*)
      # * :pin2 (nil) - Optionally supply a second pin to match on
      # * :state2 (nil) - State for the second pin (required if :pin2 is supplied)
      # * :check_for_fails (false) - Flushes the pipeline and handshakes with the tester (passing readcode 100) prior to the match (to allow binout of fails encountered before the match)
      # * :force_fail_on_timeout (true) - Force a vector mis-compare if the match loop times out
      # * :on_timeout_goto ("") - Optionally supply a label to branch to on timeout, by default will continue from the end of the match loop
      # * :on_pin_match_goto ("") - Optionally supply a label to branch to when pin 1 matches, by default will continue from the end of the match loop
      # * :on_pin2_match_goto ("") - Optionally supply a label to branch to when pin 2 matches, by default will continue from the end of the match loop
      # * :multiple_entries (false) - Supply an integer to generate multiple entries into the match (each with a unique readcode), this can be useful when debugging patterns with multiple matches
      # * :force_fail_on_timeout (true) - force pattern to fail if timeout occurs
      # * :global_loops (false) - whether match loop loops should use global labels
      # * :manual_stop (false) - whether to use extra cpuB flag to resolve IG-XL v.3.50.xx bug where VBT clears cpuA immediately
      #                          at start of PatFlagFunc instead of at end.  Use will have to manually clear cpuB to resume this pattern.
      # ==== Examples
      #   $tester.wait(:match => true, :time_in_us => 5000, :pin => $top.pin(:done), :state => :high)
      def match(pin, state, timeout, options = {})
        options = {
          check_for_fails:       false,
          on_timeout_goto:       false,
          pin2:                  false,
          state2:                false,
          on_pin_match_goto:     false,
          multiple_entries:      false,
          force_fail_on_timeout: true,
          global_loops:          false,
          manual_stop:           false,
          clr_fail_post_match:   false
        }.merge(options)

        match_block(timeout, options) do |match_conditions, fail_conditions|
          # Define match conditions
          match_conditions.add do
            state == :low ? pin.expect_lo : pin.expect_hi
            cc "Check if #{pin.name} is #{state == :low ? 'low' : 'high'}"
            cycle
            pin.dont_care
          end

          if options[:pin2]
            match_conditions.add do
              state == :low ? pin.expect_hi : pin.expect_lo
              options[:state2] == :low ? options[:pin2].expect_lo : options[:pin2].expect_hi
              cc "Check if #{options[:pin2].name} is #{options[:state2] == :low ? 'low' : 'high'}"
              cycle
              options[:pin2].dont_care
              pin.dont_care
            end
          end

          # Define fail conditions
          fail_conditions.add do
            state == :low ? pin.expect_lo : pin.expect_hi
            cc "Check if #{pin.name} is #{state == :low ? 'low' : 'high'}"
            if options[:pin2]
              options[:state2] == :low ? options[:pin2].expect_lo : options[:pin2].expect_hi
              cc "Check if #{options[:pin2].name} is #{options[:state2] == :low ? 'low' : 'high'}"
            end
            cycle
            pin.dont_care
            options[:pin2].dont_care if options[:pin2]
          end
        end
      end

      # Call a match loop.
      #
      # Normally you would put your match loop in a global subs pattern, then you can
      # call it via this method. This method automatically syncs match loop naming with
      # the match generation flow, no arguments required.
      #
      # This is an IGXLBasedTester specific API.
      #
      # ==== Examples
      #   $tester.cycle
      #   $tester.call_match  # Calls the match loop, or the first entry point if you have multiple
      #   $tester.cycle
      #   $tester.call_match  # Calls the match loop, or the second entry point if you have multiple
      def call_match
        @match_counter = @match_counter || 0
        call_subroutine("match_done_#{@match_counter}")
        @match_counter += 1 unless @match_counter == (@match_entries || 1) - 1
      end

      # Apply a label to the pattern.
      #
      # No additional vector is generated.
      # Arguments:
      #    name : label name
      #  global : (optional) whether to apply global label, default=false
      #
      # ==== Examples
      #   $tester.label("something_significant")
      #   $tester.label("something_significant",true) # apply global label
      def label(name, global = false)
        global_opt = (global) ? 'global ' : ''
        microcode global_opt + name + ':'
      end

      # * J750 Specific *
      #
      # Set a readcode.
      #
      # Use the set an explicit readcode for communicating with the tester. This method
      # will generate an additional vector.
      #
      # ==== Examples
      #   $tester.set_code(55)
      def set_code(code)
        cycle(microcode: "set_code #{code}")
      end

      # Branch execution to the given point.
      #
      # This generates a new vector with a jump instruction to a given label. This method
      # will generate an additional vector.
      #
      # ==== Examples
      #   $tester.branch_to("something_significant")
      def branch_to(label)
        cycle(microcode: "jump #{label}")
      end
      alias_method :branch, :branch_to

      # Add loop to the pattern.
      #
      # Pass in a name for the loop and the number of times to execute it, all vectors
      # generated by the given block will be captured in the loop.
      #
      # Optional arguments: global - whether to apply global label (default=false)
      #                label_first - whether to apply loop label before loop vector or not
      #
      # ==== Examples
      #   $tester.loop_vectors("pulse_loop", 3) do   # Do this 3 times...
      #       $tester.cycle
      #       some_other_method_to_generate_vectors
      #   end
      def loop_vectors(name, number_of_loops, global = false, label_first = false)
        if number_of_loops > 1
          @loop_counters ||= {}
          if @loop_counters[name]
            @loop_counters[name] += 1
          else
            @loop_counters[name] = 0
          end
          loop_name = @loop_counters[name] == 0 ? name : "#{name}_#{@loop_counters[name]}"
          if label_first
            global_opt = (global) ? 'global ' : ''
            microcode "#{global_opt}#{loop_name}: "
          end
          cycle(microcode: "loopA #{number_of_loops}")
          unless label_first
            global_opt = (global) ? 'global ' : ''
            cycle(microcode: "#{global_opt}#{loop_name}: ")
          end
          yield
          cycle(microcode: "end_loopA #{loop_name}")
        else
          yield
        end
      end
      alias_method :loop_vector, :loop_vectors

      # An internal method called by Origen Pattern Create to create the pattern header
      def pattern_header(options = {})
        options = {
          instruments:    {},            # Provide instruments here if desired as a hash (e.g. "mto" => "dgen_2bit")
          subroutine_pat: false,
          svm_only:       true,          # Whether 'svm_only' can be specified
          group:          false,            # If true the end pattern is intended to run within a pattern group
          high_voltage:   false,         # Supply a pin name here to declare it as an HV instrument (not yet defined)
          freq_counter:   false,     # Supply a pin name here to declare it as a frequency counter
          memory_test:    false,      # If true, define 2-bit MTO DGEN as instrument
        }.merge(options)

        if level_period?
          microcode "import tset #{min_period_timeset.name};"
        else
          called_timesets.each do |timeset|
            microcode "import tset #{timeset.name};"
          end
        end
        unless options[:group]    # Withhold imports for pattern groups, is this correct?
          called_subroutines.each do |sub_name|
            # Don't import any called subroutines that are declared in the current pattern
            microcode "import svm_subr #{sub_name};" unless local_subroutines.include?(sub_name)
          end
        end

        # If memory test, then add to instruments hash
        if options[:memory_test]
          options[:instruments].merge!('mto' => 'dgen_2bit')
        end

        if options[:svm_only]
          microcode "svm_only_file = #{options[:subroutine_pat] ? 'yes' : 'no'};"
        end

        microcode "opcode_mode = #{@opcode_mode};"
        microcode "digital_inst = #{options[:digital_inst]};" if options[:digital_inst]
        microcode 'compressed = yes;' # if $dut.gzip_patterns

        # Take care of any instruments
        if options[:instruments].length > 0
          microcode 'instruments = {'
          options[:instruments].each do |instrument, setting|
            if "#{setting}" == 'nil'
              microcode "               #{instrument};"
            else
              microcode "               #{instrument}:#{setting};"
            end
          end
          microcode '}'
        end

        options[:high_voltage] = @use_hv_pin
        microcode "pin_setup = {#{options[:high_voltage]} high_voltage;}" if options[:high_voltage]
        microcode "pin_setup = {#{options[:freq_counter]} freq_count;}" if options[:freq_counter]
        microcode ''

        pin_list = ordered_pins.map(&:name).join(', ')

        # here indicate pattern header specific stuff
        yield pin_list
        if ordered_pins.size > 0
          max_pin_name_length = ordered_pins.map(&:name).max { |a, b| a.length <=> b.length }.length
          pin_widths = ordered_pins.map { |p| p.size - 1 }

          max_pin_name_length.times do |i|
            cc((' ' * 93) + ordered_pins.map.with_index { |p, x| ((p.name[i] || ' ') + ' ' * pin_widths[x]).gsub('_', '-') }.join(' '))
          end
        end
      end

      # An internal method called by Origen to generate the pattern footer
      def pattern_footer(options = {})
        options = {
          subroutine_pat: false,
          end_in_ka:      false,
          end_with_halt:  false,
          end_module:     true
        }.merge(options)
        $tester.align_to_last
        # cycle(:microcode => "#{$dut.end_of_pattern_label}:") if $dut.end_of_pattern_label
        if options[:end_in_ka]
          $tester.cycle microcode: 'keep_alive'
        else
          if options[:end_with_halt]
            $tester.cycle microcode: 'halt'
          else
            if options[:end_module]
              $tester.cycle microcode: 'end_module' unless options[:subroutine_pat]
            else
              $tester.cycle
            end
          end
        end
        microcode '}'
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
        timeset = vec.timeset ? "> #{vec.timeset.name}" : ''
        pin_vals = vec.pin_vals ? "#{vec.pin_vals} ;" : ''
        if vec.repeat > 1
          microcode = "repeat #{vec.repeat}"
        else
          microcode = vec.microcode ? vec.microcode : ''
        end
        if vec.pin_vals && ($_testers_enable_vector_comments || vector_comments)
          comment = " // #{vec.number}:#{vec.cycle} #{vec.inline_comment}"
        else
          comment = vec.inline_comment.empty? ? '' : " // #{vec.inline_comment}"
        end

        "#{microcode.ljust(65)}#{timeset.ljust(31)}#{pin_vals}#{comment}"
      end

      # Override this to force the formatting to match the v1 J750 model (easier diffs)
      def push_microcode(code) # :nodoc:
        stage.store(code.ljust(65) + ''.ljust(31))
      end
      alias_method :microcode, :push_microcode

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
        pinmap = Origen.pin_bank.pins
        pinmap.each { |id, pin| pin.repeat_previous = true }
        yield
        pinmap.each { |id, pin| pin.repeat_previous = false }
      end

      def ignore_fails(*pins)
        pins.each(&:suspend)
        yield
        pins.each(&:resume)
      end

      def enable_flag(options = {})
        options = { flagnum: 4,      # default flag to use
                }.merge(options)

        if options[:flagnum] > @flags.length
          abort "ERROR! Invalid flag value passed to 'enable_flag' method!\n"
        end
        flagname = @flags[options[:flagnum] - 1]
        update_vector(microcode: "#{@microcode[:enable]}(#{flagname})")
      end

      def set_flag(options = {})
        options = { flagnum: 4,      # default flag to use
                }.merge(options)

        if options[:flagnum] > @flags.length
          abort "ERROR! Invalid flag value passed to 'set_flag' method!\n"
        end
        flagname = @flags[options[:flagnum] - 1]
        update_vector(microcode: "#{@microcode[:set_flag]}(#{flagname})")
      end

      def cycle(options = {})
        if @mask_vector
          # tack on masking opcodes
          super(options.merge(microcode: "#{options[:microcode]} #{@microcode[:mask_vector]}"))
        else
          super(options)
        end
      end

      def mask_fails(setclr)
        @mask_vector = setclr
      end
    end
  end
end
