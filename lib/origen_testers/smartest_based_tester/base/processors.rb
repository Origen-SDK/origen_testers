module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        # Include any V93K specific AST processors here
        autoload :IfRanCleaner, 'origen_testers/smartest_based_tester/base/processors/if_ran_cleaner'
        autoload :EmptyBranchCleaner, 'origen_testers/smartest_based_tester/base/processors/empty_branch_cleaner'
        autoload :FlagOptimizer, 'origen_testers/smartest_based_tester/base/processors/flag_optimizer'
        autoload :ExtractSetVariables, 'origen_testers/smartest_based_tester/base/processors/extract_set_variables'
        autoload :AdjacentIfCombiner, 'origen_testers/smartest_based_tester/base/processors/adjacent_if_combiner'
        autoload :ContinueImplementer, 'origen_testers/smartest_based_tester/base/processors/continue_implementer'
        autoload :ExtractRunFlagTable, 'origen_testers/smartest_based_tester/base/processors/extract_run_flag_table'
      end
    end
  end
end
