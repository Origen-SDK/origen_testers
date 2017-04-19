module OrigenTesters
  module StilBasedTester
    class D10 < Base
      def d10?
        true
      end
    end
  end
  D10 = StilBasedTester::D10
end
