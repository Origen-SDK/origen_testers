module OrigenTesters
  module StilBasedTester
    class STIL < Base
    end
  end
  # Support OrigenTesters::STIL.new
  STIL = StilBasedTester::STIL
end
