module OrigenTesters
  module IGXLBasedTester
    autoload :Base,                'origen_testers/igxl_based_tester/base.rb'
    autoload :J750,                'origen_testers/igxl_based_tester/j750.rb'
    autoload :J750_HPT,            'origen_testers/igxl_based_tester/j750_hpt.rb'
    autoload :UltraFLEX,           'origen_testers/igxl_based_tester/ultraflex.rb'

    require 'origen_testers/igxl_based_tester/decompiler'
  end
  # Convenience/Legacy names without the IGXLBasedTester namespace
  autoload :J750,                  'origen_testers/igxl_based_tester/j750.rb'
  autoload :J750_HPT,              'origen_testers/igxl_based_tester/j750_hpt.rb'
  autoload :UltraFLEX,             'origen_testers/igxl_based_tester/ultraflex.rb'
end
