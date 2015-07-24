module Testers
  module SmartestBasedTester
    class V93K < Base
      require 'testers/smartest_based_tester/v93k/generator.rb'
    end
  end
  V93K = SmartestBasedTester::V93K
end
