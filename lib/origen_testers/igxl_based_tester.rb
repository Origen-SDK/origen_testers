module OrigenTesters
  module IGXLBasedTester
    autoload :Base,                'origen_testers/igxl_based_tester/base.rb'
    autoload :J750,                'origen_testers/igxl_based_tester/j750.rb'
    autoload :J750_HPT,            'origen_testers/igxl_based_tester/j750_hpt.rb'
    autoload :UltraFLEX,           'origen_testers/igxl_based_tester/ultraflex.rb'
  end
  # Convenience/Legacy names without the IGXLBasedTester namespace
  autoload :J750,                  'origen_testers/igxl_based_tester/j750.rb'
  autoload :J750_HPT,              'origen_testers/igxl_based_tester/j750_hpt.rb'
  autoload :UltraFLEX,             'origen_testers/igxl_based_tester/ultraflex.rb'
  # Not sure if there's a better place to load this class
  autoload :MemoryStyle,           'origen_testers/memory_style.rb'
end
