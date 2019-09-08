module OrigenTesters
  module Timing
    require 'origen_testers/timing/timeset'
    require 'origen_testers/timing/timing_api'

    extend ActiveSupport::Concern
    include TimingAPI

    # Each time the toplevel is instantiated, we'll reset the timing, preserving
    # the behavior when the timesets were stored on the tester object directly.
    class TopLevelWatcher
      include Origen::PersistentCallbacks

      def before_load_target
        OrigenTesters::Timing.reset!
      end
    end
    @top_level_watcher = TopLevelWatcher.new

    included do
      # When set to true all pattern vectors will be converted to use the same period (the
      # shortest period used in the pattern).
      #
      # @example
      #   $tester.set_timeset("fast", 40)
      #   2.cycles                        #    fast   1 0 0 1 0
      #                                   #    fast   1 0 0 1 0
      #
      #   $tester.level_period = false  # Without levelling enabled
      #   $tester.set_timeset("slow", 80)
      #   2.cycles                        #    slow   1 0 0 1 0
      #                                   #    slow   1 0 0 1 0
      #
      #   $tester.level_period = true   # With levelling enabled
      #   $tester.set_timeset("slow", 80)
      #   2.cycles                        #    fast   1 0 0 1 0
      #                                   #    fast   1 0 0 1 0
      #                                   #    fast   1 0 0 1 0
      #                                   #    fast   1 0 0 1 0
      #
      # @see Timing#timing_toggled_pins
      attr_accessor :level_period
      alias_method :level_period?, :level_period
      attr_writer :timing_toggled_pins
    end

    def self.timesets!
      @timesets = {}.with_indifferent_access
    end

    def self.reset!
      timesets!
      @timeset = nil
      @_last_timeset_change = nil
      @min_period_timeset = nil
    end

    def self.set_timeset(timeset, period_in_ns = nil)
      def self._set_timeset_(timeset, period_in_ns = nil)
        # If the period_in_ns was given, use that.
        # Alternatively, the period_in_ns may have been set on the Timeset object
        # already.
        # If not, then complain that we need a period_in_ns before proceeding.
        if period_in_ns
          timeset._period_in_ns_ = period_in_ns
          # elsif !timeset.period_in_ns?
          # fail 'You must supply a period_in_ns argument to set_timeset'
        end

        if @timeset
          timeset_changed(timeset)
        else
          @timeset = timeset
        end
        timeset.called = true
        @timeset = timeset
        timeset
      end

      if timeset.is_a?(Array)
        timeset, period_in_ns = timeset[0], timeset[1]
      end
      timeset ||= @timeset
      if timeset.is_a?(Origen::Pins::Timing::Timeset) || timeset.is_a?(OrigenTesters::Timing::Timeset)
        timeset = timeset.id.to_sym
      end
      timeset = (timesets[timeset] || lookup_or_register_timeset(timeset.to_s.chomp, period_in_ns: period_in_ns))

      if block_given?
        original = @timeset
        _set_timeset_(timeset, period_in_ns)
        yield
        timeset = original
        period_in_ns = timeset.period_in_ns
      end
      _set_timeset_(timeset, period_in_ns)

      if @min_period_timeset && period_in_ns
        @min_period_timeset = timeset if timeset.shorter_period_than?(@min_period_timeset)
      else
        @min_period_timeset = timeset
      end
      timeset
    end
    singleton_class.send(:alias_method, :with_timeset, :set_timeset)

    def self.min_period_timeset
      @min_period_timeset
    end

    def self.timesets
      @timesets || timesets!
    end

    # Given a timeset name or object, either returns it, if it exists, or creates it, and returns
    # the newly created timeset.
    def self.lookup_or_register_timeset(t, period_in_ns: nil)
      if t.is_a?(Origen::Pins::Timing::Timeset)
        timesets[t.id] ||= Timeset.new(name: t.id, period_in_ns: period_in_ns)
      else
        timesets[t] ||= Timeset.new(name: t, period_in_ns: period_in_ns)
      end
    end

    # Returns true if the current timeset is defined. False otherwise.
    def self.timeset?(t)
      if t.respond_to?(:name)
        timesets.key?(t.name)
      else
        timesets.key?(t)
      end
    end

    def self.timeset
      @timeset
    end

    def self.current_timeset
      @timeset
    end

    def self.period_in_ns
      if timeset
        timeset.period_in_ns
      end
    end

    def self.timeset_changed(timeset)
      if tester && tester.last_vector && tester.last_vector.timeset != timeset
        change = { old: tester.last_vector.timeset, new: timeset }
        # Suppress any duplicate calls
        if !@_last_timeset_change ||
           (@_last_timeset_change[:new] != change[:new] &&
             @_last_timeset_change[:old] != change[:old])
          tester.before_timeset_change(change)
        end
        @_last_timeset_change = change
      end
    end

    def self.current_period_in_ns
      if timeset
        timeset.period_in_ns
      end
    end
    singleton_class.send(:alias_method, :period, :current_period_in_ns)
    singleton_class.send(:alias_method, :current_period, :current_period_in_ns)
    singleton_class.send(:alias_method, :period_in_ns, :current_period_in_ns)

    def self.period_in_secs
      if timeset
        timeset.period_in_secs
      end
    end
    singleton_class.send(:alias_method, :period_in_seconds, :period_in_secs)

    # Returns any timesets that have been called during this execution.
    # @return [Array] Array of OrigenTesters::Timing::Timeset objects that have been used so far.
    def self.called_timesets
      timesets.select { |n, t| t.called? }.values
    end
    # alias_method :called_timesets_by_instance, :called_timesets

    # Similar to {#called_timesets}, but returns the name of the timesets instead.
    # @return [Array] Array of names corresponding to the timesets that have been used so far.
    def self.called_timesets_by_name
      timesets.select { |n, t| t.called? }.keys
    end
  end
end
