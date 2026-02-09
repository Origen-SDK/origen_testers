module OrigenTesters
  module Timing
    module TimingAPI
      # @see Timing#level_period
      #
      # When period levelling is enabled, vectors will be expanded like this:
      #   $tester.set_timeset("fast", 40)
      #   2.cycles                        #    fast   1 0 0 1 0
      #                                   #    fast   1 0 0 1 0
      #   # Without levelling enabled
      #   $tester.set_timeset("slow", 80)
      #   2.cycles                        #    slow   1 0 0 1 0
      #                                   #    slow   1 0 0 1 0
      #   # With levelling enabled
      #   $tester.set_timeset("slow", 80)
      #   2.cycles                        #    fast   1 0 0 1 0
      #                                   #    fast   1 0 0 1 0
      #                                   #    fast   1 0 0 1 0
      #                                   #    fast   1 0 0 1 0
      #
      # The overall time of the levelled/expanded vectors matches that of the unlevelled
      # case. i.e. 4 cycles at fast speed (4 * 40ns = 160ns) is equivalent to 2 cycles
      # at slow speed (2 * 80ns = 160ns).
      #
      # However, what if pin 1 in the example above was a clk pin where the 1 -> 0 transition
      # was handled by the timing setup for that pin.
      # In that case the levelled code is no longer functionally correct since it contains
      # 4 clock pulses while the unlevelled code only has 2.
      #
      # Such pins can be specified via this attribute and the levelling logic will then
      # automatically adjust the drive state to keep the number of pulses correct.
      # It would automatically adjust to the alternative logic state where 0 means 'on'
      # and 1 means 'off' if applicable.
      #
      #   $tester.timing_toggled_pins << $dut.pin(:tclk)  # This is pin 1
      #
      #   $tester.set_timeset("fast", 40)
      #   2.cycles                        #    fast   1 0 0 1 0
      #                                   #    fast   1 0 0 1 0
      #   # Without levelling enabled
      #   $tester.set_timeset("slow", 80)
      #   2.cycles                        #    slow   1 0 0 1 0
      #                                   #    slow   1 0 0 1 0
      #   # With levelling enabled
      #   $tester.set_timeset("slow", 80)
      #   2.cycles                        #    fast   1 0 0 1 0
      #                                   #    fast   0 0 0 1 0
      #                                   #    fast   1 0 0 1 0
      #                                   #    fast   0 0 0 1 0
      #
      # Multiple pins an be specified like this:
      #   $tester.timing_toggled_pins = [$dut.pin(:tclk), $dut.pin(:clk)]   # Overrides any pins added elsewhere
      #   $tester.timing_toggled_pins << [$dut.pin(:tclk), $dut.pin(:clk)]  # In addition to any pins added elsewhere
      def timing_toggled_pins
        @timing_toggled_pins ||= []
        @timing_toggled_pins.flatten!
        @timing_toggled_pins
      end

      # Set the timeset for the next vectors, this will remain in place until the next
      # time this is called.
      #
      #   $tester.set_timeset("bist_25mhz", 40)
      #
      # This method also accepts a block in which case the contained vectors will generate
      # with the supplied timeset and subsequent vectors will return to the previous timeset
      # automatically.
      #
      #   $tester.set_timeset("bist_25mhz", 40) do
      #     $tester.cycle
      #   end
      #
      # The arguments can also be supplied as a single array, or not at all. In the latter case
      # the existing timeset will simply be preserved. This is useful if you have timesets that
      # can be conditionally set based on the target.
      #
      #   # Target 1
      #   $soc.readout_timeset = ["readout", 120]
      #   # Target 2
      #   $soc.readout_timeset = false
      #
      #   # This code is compatible with both targets, in the first case the timeset will switch
      #   # over, in the second case the existing timeset will be preserved.
      #   $tester.set_timeset($soc.readout_timeset) do
      #     $tester.cycle
      #   end
      def set_timeset(timeset, period_in_ns = nil, &block)
        OrigenTesters::Timing.set_timeset(timeset, period_in_ns, &block)
      end
      alias_method :with_timeset, :set_timeset

      def timesets
        OrigenTesters::Timing.timesets
      end

      def timeset?(t)
        OrigenTesters::Timing.timeset?(t)
      end

      # Returns the timeset (a Timeset object) with the shortest period that has been
      # encountered so far in the course of generating the current pattern.
      #
      # A tester object is re-instantiated at the start of every pattern which will reset
      # this variable.
      def min_period_timeset
        OrigenTesters::Timing.min_period_timeset
      end

      def before_timeset_change(options = {})
      end

      # Returns the current period in ns, or nil, if no timeset has been set.
      def period_in_ns
        OrigenTesters::Timing.period_in_ns
      end

      def period_in_secs
        OrigenTesters::Timing.period_in_ns
      end
      alias_method :period_in_seconds, :period_in_secs

      # Cause the pattern to wait.
      # The following options are available to help you specify the time to wait:
      # * :cycles - delays specified in raw cycles, the test model is responsible for translating this into a sequence of valid repeat statements
      # * :time_in_ns - time specified in nano-seconds
      # * :time_in_us - time specified in micro-seconds
      # * :time_in_ms - time specified in milli-seconds
      # * :time_in_s - time specified in seconds
      # If more than one option is supplied they will get added together to give a final
      # delay time expressed in cycles.
      # ==== Examples
      #   $tester.wait(cycles: 100, time_in_ns: 200)   # Wait for 100 cycles + 200ns
      # This method can also be used to trigger a match loop in which case the supplied time
      # becomes the time out for the match. See the J750#match method for full details of the
      # available options.
      #   $tester.wait(match: true, state: :high, pin: $dut.pin(:done), time_in_ms: 500)
      def wait(options = {})
        options = {
          cycles:         0,
          time_in_cycles: 0,
          time_in_us:     0,
          time_in_ns:     0,
          time_in_ms:     0,
          time_in_s:      0,
          match:          false   # Set to true to invoke a match loop where the supplied delay
          # will become the timeout duration
        }.merge(options)

        cycles = 0
        cycles += options[:cycles] + options[:time_in_cycles]
        cycles += s_to_cycles(options[:time_in_s])
        cycles += ms_to_cycles(options[:time_in_ms])
        cycles += us_to_cycles(options[:time_in_us])
        cycles += ns_to_cycles(options[:time_in_ns])

        time = cycles * current_period_in_ns   # Total delay in ns
        case
          when time < 1000                      # When less than 1us
            cc "Wait for #{'a maximum of ' if options[:match]}#{time}ns"
          when time < 1_000_000                   # When less than 1ms
            cc "Wait for #{'a maximum of ' if options[:match]}#{(time.to_f / 1000).round(1)}us"        # Display delay in us
          when time < 1_000_000_000                # When less than 1s
            cc "Wait for #{'a maximum of ' if options[:match]}#{(time.to_f / 1_000_000).round(1)}ms"
          else
            cc "Wait for #{'a maximum of ' if options[:match]}%.2fs" % (time.to_f / 1_000_000_000)
        end

        if cycles > 0   # Allow this function to be called with 0 in which case it will just return
          if options[:match]
            if block_given?
              match_block(cycles, options) { yield }
            else
              match(options[:pin], options[:state], cycles, options)
            end
          else
            delay(cycles)
          end
        end
      end

      # @see Timing#wait
      # @api private
      # This should not be called directly, call via tester#wait
      def delay(cycles, options = {})
        (cycles / max_repeat_loop).times do
          if block_given?
            yield options.merge(repeat: max_repeat_loop)
          else
            cycle(options.merge(repeat: max_repeat_loop))
          end
        end
        if block_given?
          yield options.merge(repeat: (cycles % max_repeat_loop))
        else
          cycle(options.merge(repeat: (cycles % max_repeat_loop)))
        end
      end

      def max_repeat_loop
        @max_repeat_loop || 65_535
      end

      def min_repeat_loop
        @min_repeat_loop
      end

      # Returns any timesets that have been called during this execution.
      # @return [Array] Array of OrigenTesters::Timing::Timeset objects that have been used so far.
      def called_timesets
        OrigenTesters::Timing.called_timesets
      end
      alias_method :called_timesets_by_instance, :called_timesets

      # Similar to {#called_timesets}, but returns the name of the timesets instead.
      # @return [Array] Array of names corresponding to the timesets that have been used so far.
      def called_timesets_by_name
        OrigenTesters::Timing.called_timesets_by_name
      end

      def current_period_in_ns
        OrigenTesters::Timing.current_period_in_ns
      end
      alias_method :current_period, :current_period_in_ns
      alias_method :period, :current_period_in_ns

      def current_timeset
        OrigenTesters::Timing.current_timeset
      end
      alias_method :timeset, :current_timeset

      # Convert the supplied number of cycles to a time, based on the SoC defined cycle period
      def cycles_to_time(cycles) # :nodoc:
        (cycles * current_period_in_ns).to_f / 1_000_000_000
      end

      # This function can be used to generate a clock or some other repeating function
      # that spans accross a range of vectors.
      # The period of each cycle and the duration of the sequence are supplied via the following
      # options:
      # * :period_in_cycles
      # * :period_in_ns
      # * :period_in_us
      # * :period_in_ms
      # * :duration_in_cycles
      # * :duration_in_ns
      # * :duration_in_us
      # * :duration_in_ms
      # If multiple definitions for either option are supplied then they will be added
      # together.
      # ==== Example
      #   # Supply a clock pulse on :pinA for 100ms
      #   $tester.count(:period_in_cycles => 10, :duration_in_ms => 100) do
      #       $top.pin(:pinA).drive!(1)
      #       $top.pin(:pinA).drive!(0)
      #   end
      def count(options = {})
        options = { period_in_cycles: 0, period_in_ms: 0, period_in_us: 0, period_in_ns: 0,
                    duration_in_cycles: 0, duration_in_ms: 0, duration_in_us: 0, duration_in_ns: 0 }.merge(options)

        period_cycles = options[:period_in_cycles] + ms_to_cycles(options[:period_in_ms]) +
                        us_to_cycles(options[:period_in_us]) + ns_to_cycles(options[:period_in_ns])

        duration_cycles = options[:duration_in_cycles] + ms_to_cycles(options[:duration_in_ms]) +
                          us_to_cycles(options[:duration_in_us]) + ns_to_cycles(options[:duration_in_ns])

        total = 0
        while total < duration_cycles
          wait(time_in_cycles: period_cycles)
          yield								# Return control back to caller
          total += period_cycles
        end
      end

      private

      def s_to_cycles(time) # :nodoc:
        ((time.to_f) * 1000 * 1000 * 1000 / current_period_in_ns).to_int
      end

      def ms_to_cycles(time) # :nodoc:
        ((time.to_f) * 1000 * 1000 / current_period_in_ns).to_int
      end

      def us_to_cycles(time) # :nodoc:
        ((time.to_f * 1000) / current_period_in_ns).to_int
      end

      def ns_to_cycles(time) # :nodoc:
        (time.to_f / current_period_in_ns).to_int
      end

      def cycles_to_us(cycles) # :nodoc:
        ((cycles.to_f * current_period_in_ns) / (1000)).ceil
      end

      def cycles_to_ms(cycles) # :nodoc:
        ((cycles.to_f * current_period_in_ns) / (1000 * 1000)).ceil
      end

      # Cycles to tenths of a second
      def cycles_to_ts(cycles) # :nodoc:
        ((cycles.to_f * current_period_in_ns) / (1000 * 1000 * 100)).ceil
      end
    end
  end
end
