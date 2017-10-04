module OrigenTesters
  module SmartestBasedTester
    class Base
      class TestSuites
        # Origen::Tester::Generator not included since test suites do not have their
        # own top-level sheet, they will be incorporated within the flow sheet

        attr_accessor :flow, :collection

        def initialize(flow)
          @flow = flow
          @collection = []
        end

        def filename
          flow.filename
        end

        def add(name, options = {})
          name = make_unique(name)
          suite = platform::TestSuite.new(name, options)
          @collection << suite
          # c = Origen.interface.consume_comments
          # Origen.interface.descriptions.add_for_test_definition(name, c)
          suite
        end
        alias_method :run, :add
        alias_method :run_and_branch, :add

        def platform
          Origen.interface.platform
        end

        def finalize
          # collection.each do |suite|
          # end
        end

        def sorted_collection
          @collection.sort_by { |ts| ts.name.to_s }
        end

        private

        def make_unique(name)
          @existing_names ||= {}
          if @existing_names[name.to_sym]
            @existing_names[name.to_sym] += 1
            "#{name}_#{@existing_names[name.to_sym]}"
          else
            @existing_names[name.to_sym] = 0
            name
          end
        end
      end
    end
  end
end
