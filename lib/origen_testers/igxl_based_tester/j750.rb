module OrigenTesters
  module IGXLBasedTester
    # Tester model to generate .atp patterns for the Teradyne J750
    #
    # == Basic Usage
    #   $tester = Testers::J750.new
    #   $tester.cycle       # Generate a vector
    #
    # Many more methods exist to generate J750 specific micro-code, see below for
    # details.
    #
    # Also note that this class inherits from the base Tester class and so all methods
    # described there are also available.
    class J750 < Base
      require 'origen_testers/igxl_based_tester/j750/generator'

      attr_accessor :use_hv_pin
      attr_accessor :software_version

      def self.hpt_mode
        @@hpt_mode
      end

      def self.hpt_mode?
        @@hpt_mode
      end

      # Returns a new J750 instance, normally there would only ever be one of these
      # assigned to the global variable such as $tester by your target.
      def initialize(options = {})
        super(options)
        @pipeline_depth = 34  # for extended mode is vectors, for normal mode is vector pairs (54 for J750Ex)
        @use_hv_pin = false   # allows to use high voltage for a pin for all patterns
        @software_version = '3.50.40'
        @name = 'j750'
        @@hpt_mode = false
        @opcode_mode = :extended
        @loop_bits_max = 16             # maximum loop bit length

        @flags = %w(cpuA cpuB cpuC cpuD)
        @microcode[:enable] = 'enable'
        @microcode[:set_flag] = 'set_cpu'
        @microcode[:mask_vector] = 'ign ifc icc'
        @microcode[:keepalive] = 'keep_alive'
      end

      def pattern_header(options = {})
        super(options) do |pin_list|
          microcode "vector ($tset, #{pin_list})"
          microcode '{'
          unless options[:subroutine_pat]
            microcode 'start_label pattern_st:'
          end
        end
      end

      def pattern_footer(options = {})
        super(options)
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
      # * :check_for_fails (false) - Flushes the pipeline and handshakes with the tester (passing readcode 100) prior to the match (to allow binout of fails encountered before the match)
      # * :force_fail_on_timeout (true) - Force a vector mis-compare if the match loop times out
      # * :on_timeout_goto ("") - Optionally supply a label to branch to on timeout, by default will continue from the end of the match loop
      # * :on_block_match_goto ("") - Optionally supply a label to branch to when block condition is met, by default will continue from the end of the match loop.
      #   A hash will also be accepted for this argument to supply a specific label (or no label) for each block e.g. <code>{0 => "on_block_0_fail"}</code>
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

        # Flush the pipeline first and then pass control to the program to bin out any failures
        # prior to entering the match loop
        if options[:check_for_fails]
          if options[:multiple_entries]
            @match_entries.times do |i|
              microcode "global subr match_done_#{i}:"
              set_code(i + 100)
              cycle(microcode: 'jump call_tester') unless i == @match_entries - 1
            end
            microcode 'call_tester:'
          else
            set_code(100)
          end
          cc 'Wait for any prior failures to propagate through the pipeline'
          cycle(microcode: 'pipe_minus 1')
          cc 'Now handshake with the tester to bin out and parts that have failed before they got here'
          handshake(manual_stop: options[:manual_stop])
        end

        # Now do the main match loop
        cc 'Start the match loop'

        global_opt = (options[:global_loops]) ? 'global ' : ''
        microcode "#{global_opt}match_outer_loop_#{@unique_counter}:"
        cycle # (:microcode => "loopB #{outer_loop_count} ign ifc icc")
        set_loopb_vector = last_vector

        microcode "#{global_opt}match_inner_loop_#{@unique_counter}:"
        cycle # (:microcode => "loopA #{inner_loop_count} ign ifc icc")
        set_loopa_vector = last_vector

        # count cycles in match loop block passed to help with meeting
        # desired timeout value (have to back assign microcodes above)
        prematch_cycle_count = cycle_count
        match_conditions.each_with_index do |condition, i|
          mask_fails(true)
          condition.call  # match condition
          mask_fails(false)
          cc ' Wait for the result to propagate through the pipeline'
          cycle(microcode: 'pipe_minus 1 ign ifc icc')
          inc_cycle_count(@pipeline_depth - 1)                   # Account for pipeline depth
          cc "Branch if block condition #{i} met"
          cycle(microcode: "if (pass) jump block_#{i}_matched_#{@unique_counter} icc ifc")
          cycle(microcode: 'clr_flag (fail) icc')
        end
        match_conditions_cycle_count = cycle_count - prematch_cycle_count
        cc "Match loop cycle count = #{match_conditions_cycle_count}"

        # reduce timeout requested by match loop cycle count
        timeout = (timeout.to_f / match_conditions_cycle_count).ceil

        # Calculate the loop counts for the 2 loops to appropriately hit the timeout requested
        loop_value = timeout.to_f.floor

        if loop_value < (2**@loop_bits_max)
          # small value, only need to use one loop
          outer_loop_count = 1
          inner_loop_count = loop_value
        elsif loop_value < (2**(2 * @loop_bits_max))
          # 2 nested loops required
          inner_loop_count = 2**@loop_bits_max - 1
          outer_loop_count = (loop_value.to_f / inner_loop_count).ceil
        else
          abort 'ERROR: timeout value too large in tester match method!'
        end

        # retroactively set loop counter values for timeout based on cycles in match loop condition
        unless @inhibit_vectors
          set_loopb_vector.microcode = "loopB #{outer_loop_count} ign ifc icc"
          set_loopa_vector.microcode = "loopA #{inner_loop_count} ign ifc icc"
        end

        cc 'Loop back around if time remaining'
        cycle(microcode: "end_loopA match_inner_loop_#{@unique_counter} icc")
        cycle(microcode: "end_loopB match_outer_loop_#{@unique_counter} icc")

        if options[:force_fail_on_timeout]
          cc 'To get here something has gone wrong, check block again to force a pattern failure'
          fail_conditions.each(&:call)
        end

        if options[:on_timeout_goto]
          cycle(microcode: "jump #{options[:on_timeout_goto]} icc")
        else
          cycle(microcode: "jump match_loop_end_#{@unique_counter} icc")
          # cycle(:microcode => 'halt')
        end
        match_conditions.each_with_index do |condition, i|
          microcode "block_#{i}_matched_#{@unique_counter}:"
          cycle(microcode: 'pop_loop icc')
          cycle(microcode: 'clr_fail')
          if options[:on_block_match_goto]
            if options[:on_block_match_goto].is_a?(Hash)
              if options[:on_block_match_goto][i]
                custom_jump = options[:on_block_match_goto][i]
              else
                custom_jump = nil
              end
            else
              custom_jump = options[:on_block_match_goto]
            end
          end
          if custom_jump
            cycle(microcode: "jump #{custom_jump}")
          else
            # Don't do a jump on the last match block as it will naturally fall through
            # TODO: Update origen core to expose the size
            unless match_conditions.instance_variable_get(:@block_args).size == i + 1
              cycle(microcode: "jump match_loop_end_#{@unique_counter} icc")
            end
          end
        end
        microcode "match_loop_end_#{@unique_counter}:"
        if options[:clr_fail_post_match]
          cycle(microcode: 'clr_fail')
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
          manual_stop: false    # set a 2nd CPU flag in case 1st flag is automatically cleared
        }.merge(options)
        if options[:readcode]
          set_code(options[:readcode])
        end
        if options[:manual_stop]
          cycle(microcode: "#{@microcode[:enable]} (#{@flags[1]})")
          cycle(microcode: "#{@microcode[:set_flag]} (#{@flags[0]} #{@flags[1]})")
          cycle(microcode: "loop_here_#{@unique_counter}: if (flag) jump loop_here_#{@unique_counter}")
        else
          cycle(microcode: "#{@microcode[:set_flag]} (#{@flags[0]})")
          cycle(microcode: "loop_here_#{@unique_counter}: if (#{@flags[0]}) jump loop_here_#{@unique_counter}")
        end
        @unique_counter += 1  # Increment so a different label will be applied if another
        # handshake is called in the same pattern
      end

      def keep_alive(options = {})
        $tester.cycle microcode: "#{@microcode[:keepalive]}"
      end
    end
  end
  J750 = IGXLBasedTester::J750
end
