module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestMethods
        # Origen::Tester::Generator not included since test methods do not have their
        # own top-level sheet, they will be incorporated within the flow sheet

        require 'origen_testers/smartest_based_tester/base/test_methods/base_tml'
        require 'origen_testers/smartest_based_tester/base/test_methods/limits'
        autoload :AcTml, 'origen_testers/smartest_based_tester/base/test_methods/ac_tml'
        autoload :DcTml, 'origen_testers/smartest_based_tester/base/test_methods/dc_tml'
        autoload :CustomTml, 'origen_testers/smartest_based_tester/base/test_methods/custom_tml'
        autoload :SmartCalcTml, 'origen_testers/smartest_based_tester/base/test_methods/smart_calc_tml'

        attr_accessor :flow, :collection

        def initialize(flow)
          @flow = flow
          @collection = []
          @ix = 0
        end

        def filename
          flow.filename
        end

        def add(test_method, options = {})
          collection << test_method
          test_method.send 'id=', "tm_#{collection.size}"
          test_method
        end

        def [](ix)
          collection[ix]
        end

        # Returns the AC test method library
        def ac_tml
          @ac_tml ||= AcTml.new(self)
        end

        # Returns the DC test method library
        def dc_tml
          @dc_tml ||= DcTml.new(self)
        end

        # Returns the SMC test method library
        def smc_tml
          @smc_tml ||= SmartCalcTml.new(self)
        end
        alias_method :smart_calc_tml, :smc_tml

        # Creates an accessor for custom test method libraries the first time they are called
        def method_missing(method, *args, &block)
          custom_tmls = Origen.interface.send(:custom_tmls)
          if custom_tmls[method]
            tml = CustomTml.new(self, custom_tmls[method])
            instance_variable_set "@#{method}", tml
            define_singleton_method method do
              instance_variable_get("@#{method}")
            end
            send(method)
          else
            super
          end
        end

        def respond_to?(method)
          !!Origen.interface.send(:custom_tmls)[method] || super
        end

        def finalize
          collection.each do |method|
            method.finalize.call(method) if method.finalize
          end
        end

        def sorted_collection
          @collection.sort_by { |tm| tm.name.to_s }
        end
      end
    end
  end
end
