module OrigenTesters
  module SmartestBasedTester
    class V93K
      require 'origen_testers/smartest_based_tester/base/variables_file'
      class VariablesFile < Base::VariablesFile
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k/templates/vars.tf.erb"
      end
    end
  end
end
