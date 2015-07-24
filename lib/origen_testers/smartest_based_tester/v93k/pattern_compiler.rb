module OrigenTesters
  module SmartestBasedTester
    class V93K
      require 'origen_testers/smartest_based_tester/base/pattern_compiler'
      class PatternCompiler < Base::PatternCompiler
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k/templates/template.aiv.erb"
      end
    end
  end
end
