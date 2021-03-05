module OrigenTesters
  module SmartestBasedTester
    class V93K
      require 'origen_testers/smartest_based_tester/base/declarations_file'
      class DeclarationsFile < Base::DeclarationsFile
        TEMPLATE = "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k/templates/declaration_vars.tf.erb"
      end
    end
  end
end
