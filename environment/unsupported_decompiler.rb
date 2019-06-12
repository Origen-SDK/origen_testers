module OrigenTesters
  module Test
    class DummyTester
      include OrigenTesters::VectorBasedTester
    end
  end
end

OrigenTesters::Test::DummyTester.new
