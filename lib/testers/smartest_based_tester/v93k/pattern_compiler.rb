module Testers
  module SmartestBasedTester
    class V93K
      require 'testers/smartest_based_tester/base/pattern_compiler'
      class PatternCompiler < Base::PatternCompiler
        TEMPLATE = "#{RGen.root!}/lib/testers/smartest_based_tester/v93k/templates/template.aiv.erb"
      end
    end
  end
end
