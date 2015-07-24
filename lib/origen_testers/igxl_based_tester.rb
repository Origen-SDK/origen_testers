module Testers
  module IGXLBasedTester
    autoload :Base,                'testers/igxl_based_tester/base.rb'
    autoload :J750,                'testers/igxl_based_tester/j750.rb'
    autoload :J750_HPT,            'testers/igxl_based_tester/j750_hpt.rb'
    autoload :UltraFLEX,           'testers/igxl_based_tester/ultraflex.rb'
  end
  # Convenience/Legacy names without the IGXLBasedTester namespace
  autoload :J750,                  'testers/igxl_based_tester/j750.rb'
  autoload :J750_HPT,              'testers/igxl_based_tester/j750_hpt.rb'
  autoload :UltraFLEX,             'testers/igxl_based_tester/ultraflex.rb'
end
