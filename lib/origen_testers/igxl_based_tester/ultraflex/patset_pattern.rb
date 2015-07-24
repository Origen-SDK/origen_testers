module Testers
  module IGXLBasedTester
    class UltraFLEX
      require 'testers/igxl_based_tester/base/patset_pattern'
      class PatsetPattern < Base::PatsetPattern
        # Attributes for each pattern set line
        PATSET_ATTRS = %w(pattern_set td_group time_domain file_name burst start_label stop_label comment)

        PATSET_DEFAULTS = {
          burst: 'Yes'
        }

        # Generate the instance method definitions based on the above
        define
      end
    end
  end
end
