module OrigenTesters
  module IGXLBasedTester
    class J750
      require 'origen_testers/igxl_based_tester/base/patsubr_pattern'
      class PatsubrPattern < Base::PatsubrPattern
        # Attributes for each pattern subroutine line
        PATSUBR_ATTRS = %w(file_name comment)

        # Pattern subroutine defaults
        PATSUBR_DEFAULTS = {}

        # Generate the instance method definitions based on the above
        define
      end
    end
  end
end
