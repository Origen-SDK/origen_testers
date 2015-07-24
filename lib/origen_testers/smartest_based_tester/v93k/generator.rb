module OrigenTesters
  module SmartestBasedTester
    class V93K
      # Include this module in an interface class to make it a V93K interface and to give
      # access to the V93K program generator API
      module Generator
        extend ActiveSupport::Concern

        require_all "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k"
        require 'origen_testers/smartest_based_tester/base/generator'

        included do
          include Base::Generator
          PLATFORM = V93K
        end
      end
    end
  end
end
