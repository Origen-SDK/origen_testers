require 'origen/pins/timing'

module Origen
  module Pins
    module Timing
      def current_timeset_period=(p)
        if OrigenTesters::Timing.timeset.nil?
          Origen.app!.fail!(
            exception_class: OrigenTesters::Timing::InvalidModification,
            message:         'No current timeset has been defined! Cannot update the current timeset period!'
          )
        else
          OrigenTesters::Timing.set_timeset(tester.timeset, p)
        end
      end
      alias_method :current_period_in_ns=, :current_timeset_period=

      def current_timeset=(t)
        OrigenTesters::Timing.set_timeset(t)
      end
      alias_method :timeset=, :current_timeset=

      # Returns the current timeset period
      def current_timeset_period
        OrigenTesters::Timing.period_in_ns
      end
      alias_method :current_period_in_ns, :current_timeset_period

      # Returns the current timeset in seconds
      # @return [Float] Current period in seconds
      def current_period_in_secs
        OrigenTesters::Timing.period_in_secs
      end
      alias_method :current_period_in_seconds, :current_period_in_secs

      # Returns the current timeset
      def current_timeset
        OrigenTesters::Timing.timeset
      end

      # If a block is given, defines/redefines the timeset.
      # If a name is given, retrieves that timeset.
      # Otherwise, returns the current timeset.
      def timeset(*args, &block)
        if block_given?
          timesets(*args, &block)
        else
          if args.first
            timesets(args.first)
          else
            OrigenTesters::Timing.timeset
          end
        end
      end
    end
  end
end
