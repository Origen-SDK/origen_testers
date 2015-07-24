module OrigenTesters
  module SmartestBasedTester
    autoload :Base,                'origen_testers/smartest_based_tester/base.rb'
    autoload :V93K,                'origen_testers/smartest_based_tester/v93k.rb'
  end
  # Convenience/Legacy names without the SmartestBasedTester namespace
  autoload :V93K,                  'origen_testers/smartest_based_tester/v93k.rb'
end
