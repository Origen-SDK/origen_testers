require 'origen/pins/timing/timeset'

module Origen
  module Pins
    module Timing
      class Timeset
        attr_reader :_timeset_

        # Bind to the original initialize method in Origen and add registering
        # the DUT timeset to the tester.
        @orig_init = instance_method(:initialize)
        define_method(:initialize) do |*args|
          self.class.instance_variable_get(:@orig_init).bind(self).call(*args)
          instance_variable_set(:@_timeset_, OrigenTesters::Timing.lookup_or_register_timeset(self))
        end

        # Defer any missing methods to the corresponding timeset object on the tester side.
        # If the method isn't found their either, raise the standard NoMethod error.
        def method_missing(m, *args, &block)
          if _timeset_.respond_to?(m)
            _timeset_.send(m, *args, &block)
          else
            super
          end
        end
      end
    end
  end
end
