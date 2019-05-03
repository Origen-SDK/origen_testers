module OrigenTesters
  module StilBasedTester
    class D10 < Base
      def initialize(options = {})
        options = {
          pattern_only: true
        }.merge(options)
        super(options)
        @name = 'd10'
      end

      def d10?
        true
      end
    end
  end
  D10 = StilBasedTester::D10
end
