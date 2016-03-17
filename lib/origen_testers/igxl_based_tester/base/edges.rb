module OrigenTesters
  module IGXLBasedTester
    class Base
      class Edges
        include ::OrigenTesters::Generator

        attr_accessor :edges

        def initialize(options = {}) # :nodoc:
          @edges = Hash.new do |h, k|
            h[k] = {}
          end
        end

        # Defines a new Edge object for the category and pin name
        def add(grp, pin, options = {})
          grp = grp.to_sym unless grp.is_a? Symbol
          pin = pin.to_sym unless pin.is_a? Symbol
          edges[grp][pin] = platform::Edge.new(options)
        end
      end
    end
  end
end
