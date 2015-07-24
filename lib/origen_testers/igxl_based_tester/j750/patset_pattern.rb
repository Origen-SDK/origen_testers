module OrigenTesters
  module IGXLBasedTester
    class J750
      require 'origen_testers/igxl_based_tester/base/patset_pattern'
      class PatsetPattern < Base::PatsetPattern
        # Attributes for each pattern set line
        PATSET_ATTRS = %w(pattern_set file_name start_label stop_label comment)

        # Pattern set defaults
        PATSET_DEFAULTS = {
        }

        # Generate the instance method definitions based on the above
        define
      end
    end
  end
end
