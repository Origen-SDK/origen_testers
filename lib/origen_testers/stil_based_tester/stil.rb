module OrigenTesters
  module StilBasedTester
    class STIL < Base
    end
  end
  # Support OrigenTesters::STIL.new
  STIL = StilBasedTester::STIL
end
# Support STIL::Tester.new
module STIL
  Tester = OrigenTesters::StilBasedTester::STIL
end
