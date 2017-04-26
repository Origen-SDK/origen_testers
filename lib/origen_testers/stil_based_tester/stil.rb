module OrigenTesters
  module StilBasedTester
    class STIL < Base
    end
  end
end
module STIL
  Tester = OrigenTesters::StilBasedTester::STIL
end
