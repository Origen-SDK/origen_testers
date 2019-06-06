require 'origen/pins/timing'

module Origen
  module Pins
    module Timing
      # self.remove_method(:current_timeset_period=)
      # self.remove_method(:current_timeset=)

      def current_timeset_period=(p)
        if tester.timeset.nil?
          Origen.app!.fail!(
            exception_class: OrigenTesters::Timing::InvalidModification,
            message:         'No current timeset has been defined! Cannot update the current timeset period!'
          )
        else
          tester.set_timeset(tester.timeset, p)
        end
      end
      alias_method :current_period_in_ns=, :current_timeset_period=

      def current_timeset=(t)
        if tester.timeset?(t)
          tester.set_timeset(t)
        else
          n = (t.is_a?(OrigenTesters::Timing::Timeset) || t.is_a?(Origen::Pins::Timing::Timeset)) ? t.name : t
          Origen.app!.fail!(message: "No timeset :#{n} has been defined yet! Please define this timeset or use tester.set_timeset")
        end
      end

      # Returns the current timeset period
      def current_timeset_period
        tester.period_in_ns
      end
      alias_method :current_period_in_ns, :current_timeset_period

      # Returns the current timeset in seconds
      # @return [Float] Current period in seconds
      def current_period_in_secs
        tester.period_in_secs
      end
      alias_method :current_period_in_seconds, :current_period_in_secs

      # Returns the current timeset
      def current_timeset
        tester.timeset
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
            tester.timeset
          end
        end
      end
    end
  end
end
