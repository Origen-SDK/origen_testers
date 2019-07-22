module OrigenTesters
  module SmartestBasedTester
    autoload :Base,                'origen_testers/smartest_based_tester/base'
    autoload :V93K,                'origen_testers/smartest_based_tester/v93k'
  end
  # Convenience/Legacy names without the SmartestBasedTester namespace
  autoload :V93K,                  'origen_testers/smartest_based_tester/v93k'
  autoload :V93K_SMT8,             'origen_testers/smartest_based_tester/v93k_smt8'
end
