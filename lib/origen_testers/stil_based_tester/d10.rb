module OrigenTesters
  module StilBasedTester
    class D10 < Base
      def initialize
        super
        @render_pattern_section_only = true
      end

      def d10?
        true
      end
    end
  end
  D10 = StilBasedTester::D10
end
