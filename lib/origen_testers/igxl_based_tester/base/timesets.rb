module OrigenTesters
  module IGXLBasedTester
    class Base
      class Timesets
        include ::OrigenTesters::Generator

        attr_accessor :ts

        OUTPUT_PREFIX = 'TS_'
        OUTPUT_POSTFIX = ''

        def initialize # :nodoc:
          @ts = {}
        end

        def add(tsname, pin, esname, options = {})
          tsname = tsname.to_sym unless tsname.is_a? Symbol
          pin = pin.to_sym unless pin.is_a? Symbol
          esname = pin.to_sym unless esname.is_a? Symbol
          @ts.key?(tsname) ? @ts[tsname].add_edge(pin, esname) : @ts[tsname] = platform::Timeset.new(tsname, pin, esname, options)
          @ts[tsname]
        end

        def finalize(options = {})
        end
      end
    end
  end
end
