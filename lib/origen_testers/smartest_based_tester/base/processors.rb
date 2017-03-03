module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        # Include any V93K specific AST processors here
        autoload :IfRanCleaner, 'origen_testers/smartest_based_tester/base/processors/if_ran_cleaner'
        autoload :FlagOptimizer, 'origen_testers/smartest_based_tester/base/processors/flag_optimizer'
      end
    end
  end
end
