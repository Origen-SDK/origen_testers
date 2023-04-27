module OrigenTesters
  module Timing
    class InvalidModification < Origen::OrigenError
    end

    class Timeset
      attr_accessor :name, :cycled, :called
      attr_reader :period_in_ns

      def initialize(attrs = {})
        @cycled = false
        @locked = false
        @called = false

        attrs.each do |name, value|
          send("#{name}=", value)
        end

        self.period_in_ns = attrs[:period_in_ns]
      end

      # Returns true if the timeset has a shorter period than the supplied timeset
      def shorter_period_than?(timeset)
        period_in_ns < timeset.period_in_ns
      end

      # Returns true if <code>tester.cycle</code> has been called while this
      # timeset was the current timeset.
      # @return [true, false] <code>true</code> if this timeset has been cycled, <code>false</code> otherwise.
      def cycled?
        @cycled
      end

      # Returns true if this timeset does not allow changes to its period_in_ns
      def locked?
        @locked
      end
      alias_method :period_in_ns_locked?, :locked?
      alias_method :period_locked?, :locked?
      alias_method :locked, :locked?

      # Locks the current value of the timeset's period_in_ns. Attempts to further
      # adjust the period_in_ns will results in an exception.
      # @return [true, false] <code>true</code> if the period_in_ns has been locked, <code>false</code> otherwise.
      def lock!
        @locked = true
      end
      alias_method :lock_period!, :lock!
      alias_method :lock_period_in_ns!, :lock!

      # Sets the period_in_ns of this timeset and issues a callback to the <code>tester's #set_timeset</code>
      # method, if this timeset is the current timeset, keeping the tester in
      # sync with the changes to this timeset.
      # @raise [InvalidModification] If the timeset is locked.
      # @raise [InvalidModification] If period_in_ns is changed after the tester has been cycled using this timeset.
      # @return [Fixnum] The updated period in ns.
      def period_in_ns=(p)
        self._period_in_ns_ = p

        # If this is the current timeset, reset the timeset from the tester
        # side to verify that everything is in sync. Otherwise, the period_in_ns
        # here may not match what the tester/DUT has.
        if current_timeset?
          OrigenTesters::Timing.set_timeset(name, p)
        end

        # Return the period
        # rubocop:disable Lint/Void
        p
        # rubocop:enable Lint/Void
      end

      # Indicates whether a period_in_ns has been defined for this timeset.
      # @return [true, false] <code>true</code> if the period_in_ns has been set, <code>false</code> otherwise.
      def period_in_ns?
        !@period_in_ns.nil?
      end

      # Returns the current timeset in seconds
      # @return [Float] Current period in seconds
      def period_in_secs
        if period_in_ns
          period_in_ns * (10**-9)
        end
      end
      alias_method :period_in_seconds, :period_in_secs

      # Indicates whether this timeset is the current timeset.
      # @return [true, false] <code>true</code> if this timeset is the current timeset, <code>false</code> otherwise.
      def current_timeset?
        OrigenTesters::Timing.timeset == self
      end

      # Indicates whether this timeset is or has been set as the current timeset.
      # @return [true, false] <code>true</code> if this timeset is or has beent he current timeset, <code>false</code> otherwise.
      def called?
        @called
      end

      # Alias for the {#name} attr_reader.
      def id
        name.to_sym
      end

      def dut_timeset
        dut.timesets[id]
      end

      def method_missing(m, *args, &block)
        if dut_timeset && (dut_timeset.methods.include?(m) || dut_timeset.private_methods.include?(m))
          dut_timeset.send(m, *args, &block)
        else
          super
        end
      end

      # @api private
      def _period_in_ns_=(p)
        if locked?
          Origen.app.fail(
            exception_class: InvalidModification,
            message:         "Timeset :#{@name}'s period_in_ns is locked to #{@period_in_ns} ns!"
          )
        end

        # Adding this causes examples in Origen (not OrigenTesters) to fail.
        # Needs further discussion and potentially an Origen examples change.
        # if cycled? && p != period_in_ns
        #  Origen.app!.fail(
        #    exception_class: InvalidModification,
        #    message:         [
        #      "Timeset :#{name}'s period_in_ns cannot be changed after a cycle has occurred using this timeset!",
        #      "  period_in_ns change occurred at #{caller[0]}",
        #      "  Attempted to change period from #{@period_in_ns} to #{p}"
        #    ].join("\n")
        #  )
        # end
        @period_in_ns = p
        # rubocop:disable Lint/Void
        @period_in_ns
        # rubocop:enable Lint/Void
      end
    end
  end
end
