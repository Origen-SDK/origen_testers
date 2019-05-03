module OrigenTesters
  module StilBasedTester
    autoload :Base,                'origen_testers/stil_based_tester/base.rb'
    autoload :D10,                 'origen_testers/stil_based_tester/d10.rb'
    autoload :STIL,                'origen_testers/stil_based_tester/stil.rb'
  end
  # Convenience/Legacy names without the IGXLBasedTester namespace
  autoload :D10,                   'origen_testers/stil_based_tester/d10.rb'
  autoload :STIL,                  'origen_testers/stil_based_tester/stil.rb'
end
