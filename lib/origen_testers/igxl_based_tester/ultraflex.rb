module OrigenTesters
  module IGXLBasedTester
    class UltraFLEX < Base
      autoload :Generator,   'origen_testers/igxl_based_tester/ultraflex/generator.rb'

      # Tester model to generate .atp patterns for the Teradyne UltraFLEX
      #
      # == Basic Usage
      #   $tester = Testers::UltraFLEX.new
      #   $tester.cycle       # Generate a vector
      #
      # Many more methods exist to generate UltraFLEX specific micro-code, see below for
      # details.
      #
      # Also note that this class inherits from the base IGXLBasedTester class and so all methods
      # described there are also available.

      # Returns a new UltraFLEX instance, normally there would only ever be one of these
      # assigned to the global variable such as $tester by your target.
      def initialize
        super
        @pipeline_depth = 255  # for single mode
        @software_version = '8.10.10'
        @name = 'ultraflex'
        @opcode_mode = :single   # there is also :dual
        @counter_lsb_bits = 16   # individual counter bit length
        @counter_msb_bits = 12   # temporary register commonly used to extend all counters

        @flags = %w(cpuA_cond cpuB_cond cpuC_cond cpuD_cond)
        @microcode[:enable] = 'branch_expr ='
        @microcode[:set_flag] = 'set_cpu_cond'
        @microcode[:mask_vector] = 'mask'

        # Min required for a VM module-- not for SRM modules
        # this handled in pattern_header below
        @min_pattern_vectors = (@opcode_mode == :single) ? 64 : 128

        @digital_instrument = 'hsdm' # 'hsdm' for HSD1000 and UP800, ok with UP1600 though

        @capture_state = 'V'            # STV requires valid 'V' expect data

        @set_msb_issued = false        # Internal flag to keep track of set_msb usage, allowing for set_lsb to be used as a readcode
      end

      def freq_count(pin, options = {})
        fail 'Method freq_count not yet supported for UltraFLEX!'
      end

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
          use_dgen_group:      false,
          set_msb:             false
        }.merge(options)

        mto_opcode = ''

        if options[:init_counter_x]
          mto_opcode += ' xenable_load jam_reg xa jam_reg'
        end

        if options[:init_counter_y]
          mto_opcode += ' yenable_load jam_reg ya jam_reg'
        end

        if options[:inc_counter_x]
          mto_opcode += ' xa inc'
        end

        if options[:inc_counter_y]
          mto_opcode += ' ya inc'
        end

        if options[:use_dgen_group]
          mto_opcode += ' dgroup 0'
        end

        if options[:set_msb]
          microcode 'set_msb 1'
        end

        unless mto_opcode.eql?('')
          mto_opcode = '(mto =' + mto_opcode + ')'
        end

        if options[:pin_data] == :expect
          mto_opcode = 'stv'
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
          cycle(microcode: "#{mto_opcode}", dont_compress: false)
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

      def call_match
        fail 'Method call_match not yet supported for UltraFLEX!'
      end

      # Ultraflex implementation of J750-style 'set_code'
      #
      # Set a readcode, using one of the Ultraflex general-purpose counters.
      # Counter C15 is used by default, this can be changed by the caller if necessary.
      #
      # Use to set an explicit readcode for communicating with the tester. This method
      # will generate an additional vector (or 2, depending if set_msb is needed).
      #
      # NOTE: Some caveats when using this method:
      #   - When setting a counter from the pattern microcode, the actual Patgen counter value is set to n-1.
      #     This method adjusts by using a value of n+1, so the value read by the tester is the original intended value.
      #
      #   - When setting a counter from pattern microcode, the upper bits must be loaded separately using 'set_msb'.
      #     This method calls the set_msb opcode if needed - note the tester must mask the upper 16 bits to get the desired value.
      #     The set_msb opcode will also generate a second vector the first time the set_code method is called.
      #
      # ==== Examples
      #   $tester.set_code(55)
      #
      def set_code(*code)
        options = code.last.is_a?(Hash) ? code.pop : {}
        options = { counter: 'c15'
                  }.merge(options)
        cc " Using counter #{options[:counter]} as set_code replacement - value set to #{code[0]} + 1"
        if !@set_msb_issued
          set_msb(1)
          cycle   #set_msb doesn't issue a cycle
        end
        cycle(microcode: "set #{options[:counter]} #{code[0].next}")   #+1 here to align with VBT
      end

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

          if "#{loop_name}" == 'row_loop'
            cycle(microcode: 'loop c0')
          elsif "#{loop_name}" == 'quad_loop'
            cycle(microcode: 'loop c1')
          elsif "#{loop_name}" == 'page_loop_red'
            cycle(microcode: 'loop c2')
          elsif "#{loop_name}" == 'page_loop_ecc'
            cycle(microcode: 'loop c3')
          elsif "#{loop_name}" == 'page_loop_data'
            cycle(microcode: 'loop c4')
          end

          unless label_first
            global_opt = (global) ? 'global ' : ''
            cycle(microcode: "#{global_opt}#{loop_name}: ")
          end
          yield
          cycle(microcode: "end_loop #{loop_name}")
        else
          yield
        end
      end
      alias_method :loop_vector, :loop_vectors

      def pattern_header(options = {})
        options = {
          instruments: {}
        }.merge(options)

        case $tester.vector_group_size
        when 1
          @opcode_mode = :single
        when 2
          @opcode_mode = :dual
        when 4
          @opcode_mode = :quad
        end

        options[:memory_test] = memory_test_en
        options[:dc_pins] = get_dc_instr_pins

        if options[:dc_pins]
          options[:dc_pins].each do |pin|
            options[:instruments].merge!(pin => 'DCVS')
          end
        end

        # If memory test, then add to instruments hash
        if options[:memory_test]
          options[:instruments].merge!('nil' => 'mto')
        end

        super(options.merge(digital_inst: @digital_instrument,
                            memory_test:  false,
                            high_voltage: false,
                            svm_only:     false
                           )) do |pin_list|
          microcode "#{options[:subroutine_pat] ? 'srm_vector' : 'vm_vector'}"
          microcode "#{options[:pattern]} ($tset, #{pin_list})"
          microcode '{'
          # override min vector limit if subroutine pattern
          @min_pattern_vectors = 0 if options[:subroutine_pat]
          unless options[:subroutine_pat]
            microcode "start_label #{options[:pattern]}_st:"
          end
        end
      end

      def pattern_footer(options = {})
        super(options.merge(end_module: false))
      end

      # Generates a match loop based on vector condition passed in via block
      #
      # This method is not really intended to be called directly, rather you should call
      # via Tester#wait:
      #      e.g. $tester.wait(:match => true) do
      #             reg(:status_reg).bit(:done).read(1)!  # vector condition that you want to match
      #           end
      #
      # The timeout should be provided in cycles, however when called via the wait method the
      # time-based helpers (time_in_us, etc) will be converted to cycles for you.
      #
      # The following options are available to tailor the match loop behavior, defaults in
      # parenthesis:
      # * :force_fail_on_timeout (true) - Force a vector mis-compare if the match loop times out
      # * :on_timeout_goto ("") - Optionally supply a label to branch to on timeout, by default will continue from the end of the match loop
      # * :on_block_match_goto ("") - Optionally supply a label to branch to when block condition is met, by default will continue from the end of the match loop
      # * :multiple_entries (false) - Supply an integer to generate multiple entries into the match (each with a unique readcode), this can be useful when debugging patterns with multiple matches
      # * :force_fail_on_timeout (true) - force pattern to fail if timeout occurs
      # * :global_loops (false) - whether match loop loops should use global labels
      # * :manual_stop (false) - whether to use extra cpuB flag to resolve IG-XL v.3.50.xx bug where VBT clears cpuA immediately
      #                          at start of PatFlagFunc instead of at end.  Use will have to manually clear cpuB to resume this pattern.
      # ==== Examples
      #   $tester.wait(:match => true, :time_in_us => 5000, :pin => $top.pin(:done), :state => :high) do
      #     <vectors>
      #   end
      def match_block(timeout, options = {}, &block)
        options = {
          check_for_fails:       false,
          on_timeout_goto:       false,
          on_block_match_goto:   false,
          multiple_entries:      false,
          force_fail_on_timeout: true,
          global_loops:          false,
          manual_stop:           false,
          clr_fail_post_match:   false
        }.merge(options)

        unless block_given?
          fail 'ERROR: block not passed to match_block!'
        end

        if options[:check_for_fails]
          cc 'NOTE: check for fails prior to match loop not necessary on UltraFlex'
        end

        ss 'WARNING: MATCH LOOP FOR ULTRAFLEX STILL UNDER DEVELOPMENT'

        # Create BlockArgs objects in order to receive multiple blocks
        match_conditions = Origen::Utility::BlockArgs.new
        fail_conditions = Origen::Utility::BlockArgs.new

        # yield object to calling routine to get populated with blocks
        if block.arity > 0
          yield match_conditions, fail_conditions
        else
          # for backwards compatibility with Origen core call to match_block
          match_conditions.add(&block)
          fail_conditions.add(&block)
        end

        # Now do the main match loop
        cc 'Start the match loop'

        cycle # (:microcode => "set_msb #{counter_msb}")  # set_msb microcode will be set below after counting match loop cycles
        set_msb_vector = last_vector # remember the vector with set_msb opcode

        cycle(microcode: 'branch_expr = (fail)')

        global_opt = (options[:global_loops]) ? 'global ' : ''
        microcode "#{global_opt}match_loop_#{@unique_counter}:"

        cycle # (:microcode => "set c0 #{counter_lsb}")
        set_c0_vector = last_vector # remember the vector with set_c0 opcode

        microcode "match_result_loop_#{@unique_counter}:"
        cycle(microcode: 'loop c0')

        # count cycles in match loop block passed to help with meeting
        # desired timeout value (have to back assign microcodes above)
        prematch_cycle_count = cycle_count
        match_conditions.each_with_index do |condition, i|
          mask_fails(true)
          condition.call # match condition
          mask_fails(false)

          cc ' Wait for the result to propagate through the pipeline'
          cycle(microcode: 'pipe_minus 1')
          inc_cycle_count(@pipeline_depth - 1)              # Account for pipeline depth
          cc "Branch if block condition #{i} not yet met"
          cycle(microcode: "if (branch_expr) jump block_#{i}_notyet_matched_#{@unique_counter}")
          cc 'Match found'
          cycle(microcode: 'pop_loop')
          cycle(microcode: 'return') # DH ONLY IF SUBROUTINE!!
          cc 'Match not yet found'
          cycle(microcode: "block_#{i}_notyet_matched_#{@unique_counter}:")
        end

        match_conditions_cycle_count = cycle_count - prematch_cycle_count
        cc "Match loop cycle count = #{match_conditions_cycle_count}"

        # reduce timeout requested by match loop cycle count
        timeout = (timeout.to_f / match_conditions_cycle_count).ceil

        # Calculate the counter values appropriately hit the timeout requested
        match_delay_cycles = false

        # Determine full value of counter0
        counter_value = timeout.to_f.floor

        if counter_value < (2**@counter_lsb_bits)
          # small value, don't need msb temp register
          counter_msb = 1
          counter_lsb = counter_value
        elsif counter_value < (2**(@counter_lsb_bits + @counter_msb_bits))
          # larger value, but smaller than counter maximum
          counter_msb = counter_value   # set MSB (lowest LSB bits get ignored)
          counter_lsb = counter_value & (2**@counter_lsb_bits - 1) # set LSB
        elsif counter_value < (2**(@counter_lsb_bits + @counter_msb_bits)) * @max_repeat_loop
          # larger value, greater than counter, so add time delay per instance of loop to avoid using second counter
          match_delay_cycles = (counter_value.to_f / (2**(@counter_lsb_bits + @counter_msb_bits))).ceil
          counter_msb = (counter_value / match_delay_cycles).floor   # set MSB (lowest LSB bits get ignored)
          counter_lsb = counter_msb & (2**@counter_lsb_bits - 1) # set LSB
        else
          abort 'ERROR: timeout value too large in tester match method!'
        end

        # retroactively modify the counters based on cycles in match loop conditions
        set_msb_vector.microcode = "set_msb #{counter_msb}"
        set_c0_vector.microcode = "set c0 #{counter_lsb}"

        if match_delay_cycles
          cc 'Delay to meet timeout value'
          cycle(repeat: match_delay_cycles) if match_delay_cycles
        end

        cycle(microcode: "end_loop match_result_loop_#{@unique_counter}")

        if options[:force_fail_on_timeout]
          cc 'To get here something has gone wrong, check blocks again to force a pattern failure'
          fail_conditions.each do |condition|
            cycle(microcode: 'pipe_minus 1')
            condition.call
          end
        end

        @unique_counter += 1  # Increment so a different label will be applied if another
        # handshake is called in the same pattern
      end

      # Handshake with the tester.
      #
      # Will set a cpu flag (A) and wait for it to be cleared by the tester, optionally
      # pass in a read code to pass information to the tester.
      #
      # ==== Examples
      #   $tester.handshake                   # Pass control to the tester for a measurement
      #   $tester.handshake(:readcode => 10)  # Trigger a specific action by the tester
      def handshake(options = {})
        options = {
          readcode:    false,
          manual_stop: false,    # set a 2nd CPU flag in case 1st flag is automatically cleared
        }.merge(options)
        if options[:readcode]
          set_code(options[:readcode])
        end
        if options[:manual_stop]
          cycle(microcode: "#{@microcode[:enable]} (#{@flags[1]})")
          cycle(microcode: "#{@microcode[:set_flag]} (#{@flags[0]} #{@flags[1]})")
        else
          cycle(microcode: "#{@microcode[:enable]} (#{@flags[0]})")
          cycle(microcode: "#{@microcode[:set_flag]} (#{@flags[0]})")
        end
        cycle(microcode: "loop_here_#{@unique_counter}: if (branch_expr) jump loop_here_#{@unique_counter}")

        @unique_counter += 1  # Increment so a different label will be applied if another
        # handshake is called in the same pattern
      end

      # Capture a vector to the tester HRAM.
      #
      # This method applys a store vector (stv) opcode to the previous vector, note that is does
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
      #   $tester.store                # This applys the STV opcode
      #
      #   $tester.cycle                # This one gets stored
      #   $tester.cycle
      #   $tester.cycle
      #   $tester.store(:offset => -2) # Just realized I need to capture that earlier vector
      def store(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = { offset: 0,
                    opcode: 'stv'
                  }.merge(options)
        pins = pins.flatten.compact
        if pins.empty?
          fail 'For the UltraFLEX you must supply the pins to store/capture'
        end
        pins.each do |pin|
          pin.restore_state do
            pin.capture
            update_vector microcode: options[:opcode], offset: options[:offset]
            update_vector_pin_val pin, microcode: options[:opcode], offset: options[:offset]
            last_vector(options[:offset]).dont_compress = true
          end
        end
      end
      alias_method :to_hram, :store
      alias_method :capture, :store

      def reload_counters(name)
        microcode "reload #{name}"
      end

      def set_msb(integer)
        microcode "set_msb #{integer}"
        @set_msb_issued = true
      end

      # Capture the next vector generated to HRAM
      #
      # This method applies a store vector (stv) opcode to the next vector to be generated,
      # note that is does not actually generate a new vector.
      #
      # pin argument must be provided so that 'V' (valid) state can be applied to the pin
      # if not already.
      #
      # @example
      #   $tester.store_next_cycle
      #   $tester.cycle                # This is the vector that will be captured
      def store_next_cycle(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = {
          opcode: 'stv'
        }.merge(options)
        pins = pins.flatten.compact
        if pins.empty?
          fail 'For the UltraFLEX you must supply the pins to store/capture'
        end
        pins.each { |pin| pin.save; pin.capture }
        # Register this clean up function to be run after the next vector
        # is generated (SMcG: cool or what! DH: Yes, very cool!)
        preset_next_vector(microcode: options[:opcode]) do
          pins.each(&:restore)
        end
      end
      alias_method :store!, :store_next_cycle

      # Call this method at the start of any digsrc overlay operations, this method
      # issues the 'Start <waveform>' microcode
      # Required arguments:
      #                     pins
      # Optional arguments:
      #                     signal-name  (DigSrc waveform)
      #                     starte   (true or false, defaults to false)
      # Note restrestions from IG-XL help around use of starte opcode spacing to end of the current segment.
      def digsrc_start(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = {
          signal_name: '',
          starte:      false
        }.merge(options)

        pins = pins.flatten.compact
        options[:starte] ? start_syntax = 'Starte' : start_syntax = 'Start'
        microcode "(#{format_multiple_instrument_pins(pins)}:DigSrc = #{start_syntax} #{options[:signal_name]})"

        if options[:dssc_mode] == :single
          $tester.cycle(repeat: 145) # minimum of 144 cycles, adding 1 for safey measures
        elsif options[:dssc_mode] == :dual
          $tester.cycle(repeat: 289) # minimum of 288 cycles, adding 1 for safety measures
        else
          $tester.cycle(repeat: 577) # minimum of 577 cycles, adding 1 for safety measures
        end
      end

      # Call this method at the end of each digsrc overlay operation to clear the pattern
      # memory pipeline, so that the pattern is ready to do the next digsrc overlay operation.
      # Required arguments:
      #                     pins
      def digsrc_stop(*pins)
        pins = pins.flatten.compact
        microcode "(#{format_multiple_instrument_pins(pins)}:DigSrc = Stop)"
      end

      # Call this method to insert the digsrc SEND overlay microcode on the previous vector and change the pin state.
      def digsrc_send(*pins)
        dssc(pins, dssc_microcode: 'DigSrc = Send', pin_state: 'drive_mem')
      end

      # Call this method to insert the digsrc SEND overlay microcode on the next vector
      def digsrc_send_next_cycle(*pins)
        dssc_next_cycle(pins, dssc_microcode: 'DigSrc = Send', pin_state: 'drive_mem')
      end
      alias_method :digsrc_send!, :digsrc_send_next_cycle

      # Call this method to insert the digcap TRIG microcode on the previous vector
      def digcap_trig(*pins)
        dssc(pins, dssc_microcode: 'DigCap = Trig')
      end

      # Call this method to insert the digcap TRIG microcode on the next vector
      def digcap_trig_next_cycle(*pins)
        dssc_next_cycle(pins, dssc_microcode: 'DigCap = Trig')
      end
      alias_method :digcap_trig!, :digcap_trig_next_cycle

      # Call this method to insert the digcap STORE microcode on the previous vector
      def digcap_store(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = {
          offset:         0,
          dssc_microcode: 'DigCap = Store'
        }.merge(options)
        dssc(pins, options)
      end

      # Call this method to insert the digcap STORE microcode on the next vector
      def digcap_store_next_cycle(*pins)
        dssc_next_cycle(pins, dssc_microcode: 'DigSrc = Store')
      end
      alias_method :digcap_store!, :digcap_store_next_cycle

      # Call this method before each tester cycle to insert DSSC microcode and change pin state for the previous vector
      def dssc(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = {
          offset:         0,
          dssc_microcode: '',    # ie 'DigSrc = Send' or 'DigCap = Store' or 'stv'
          pin_state:      'capture'
        }.merge(options)

        pins = pins.flatten.compact
        if (options[:dssc_microcode] == 'stv')
          opcode = 'stv'
        else
          opcode = "(#{format_multiple_instrument_pins(pins)}:#{options[:dssc_microcode]})"
        end

        pins.each do |pin|
          pin.restore_state do
            case options[:pin_state]
            when 'drive_mem'
              pin.drive_mem
            when 'expect_mem'
              pin.expect_mem
            when 'capture'
              pin.capture
            else
              # no pin update by default
            end
            update_vector microcode: opcode, offset: options[:offset]
            update_vector_pin_val pin, microcode: opcode, offset: options[:offset]
            last_vector(options[:offset]).dont_compress = true
          end
        end
      end

      def dssc_next_cycle(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = {
          dssc_microcode: '',    # ie 'DigSrc = Send' or 'DigCap = Store' or 'stv'
          pin_state:      'capture'
        }.merge(options)
        pins = pins.flatten.compact

        if (options[:dssc_microcode] == 'stv')
          opcode = 'stv'
        else
          opcode = "(#{format_multiple_instrument_pins(pins)}:#{options[:dssc_microcode]})"
        end

        if pins.empty?
          fail 'You must supply a list of pins for DSSC'
        end
        pins.each do |pin|
          pin.save
          case options[:pin_state]
            when 'drive_mem'
              pin.drive_mem
            when 'expect_mem'
              pin.expect_mem
            when 'capture'
              pin.capture
            else
            # no pin update by default
          end
        end
        # Register this clean up function to be run after the next vector
        # is generated (SMcG: cool or what! DH: Yes, very cool!)
        preset_next_vector(microcode: opcode) do
          pins.each(&:restore)
        end
      end
      alias_method :dssc!, :dssc_next_cycle

      # This method builds a digsrc instrument statement for a list of pins or pingroups
      def apply_digsrc_settings(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options[:instrument] = 'DigSrc'
        apply_dssc_settings(pins, options)
      end

      # This method builds a digcap instrument statement for a list of pins or pingroups
      def apply_digcap_settings(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options[:instrument] = 'DigCap'
        apply_dssc_settings(pins, options)
      end

      # This method builds a digcap or digsrc instrument statement for a list of pins or pingroups
      def apply_dssc_settings(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = {
          instrument:       'DigCap',   # DigCap or DigSrc
          width:            1,               # Required: integer value 1 to 32
          bit_order:        nil,         # Optional: lsb or msb (default)
          mode:             nil,              # Optional: serial or parallel (default)
          format:           nil,            # Optional: (see IGXL help for details)
          data_type:        nil,         # Optional: default, long or double
          auto_cond:        nil,         # Optional: auto_cond_enable or auto_cond_disable (default)
          auto_trig_enable: nil,  # Optional: auto_trig_enable or auto_trig_disable (default)
          site_sharing:     nil,      # Optional: nonunique_sites or unique_sites (default)
          store_stv:        nil,         # Optional: store_stv_enable or store_stv_disable (default)
          receive_data:     nil,      # Optional: fail or logic (default)
        }.merge(options)

        # Build the instrument portion - only add options if they were specified, use tester defaults otherwise
        inst_string = "#{options[:instrument]} #{options[:width]}"   # required syntax
        inst_string = inst_string + ":#{options[:bit_order]}" unless options[:bit_order].nil?
        inst_string = inst_string + ":#{options[:mode]}" unless options[:mode].nil?
        inst_string = inst_string + ":format=#{options[:format]}" unless options[:format].nil?
        inst_string = inst_string + ":data_type=#{options[:data_type]}" unless options[:data_type].nil?
        inst_string = inst_string + ":#{options[:auto_cond]}" unless options[:auto_cond].nil?
        inst_string = inst_string + ":#{options[:auto_trig_enable]}" unless options[:auto_trig_enable].nil?
        if (options[:instrument] == 'DigCap')
          # these settings only available for digcap
          inst_string = inst_string + ":#{options[:store_stv]}" unless options[:store_stv].nil?
          inst_string = inst_string + ":receive_data=#{options[:receive_data]}" unless options[:receive_data].nil?
        end

        # Add new entry for this pins / instrument combination
        pins = pins.flatten.compact
        @instrument_strings.merge!(format_multiple_instrument_pins(pins) => inst_string)
      end
    end
  end
  UltraFLEX = IGXLBasedTester::UltraFLEX
end
