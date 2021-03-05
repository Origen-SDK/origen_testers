module OrigenTesters
  module SmartestBasedTester
    class V93K
      require 'origen_testers/smartest_based_tester/base/flags_file'
      class FlagsFile < Base::FlagsFile
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k/templates/flag_vars.tf.erb"
      end
    end
  end
end
