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
          @existing_names = {}
          # Test names also have to be unique vs. the current flow name
          if tester.smt8?
            @existing_names[flow.filename.sub('.flow', '').to_s] = true
          end
        end

        def filename
          flow.filename
        end

        def add(name, options = {})
          symbol = name.is_a?(Symbol)
          name = make_unique(name)
          # Ensure names given as a symbol stay as a symbol, this is more for
          # alignment to existing test cases than anything else
          name = name.to_sym if symbol
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
          name = name.to_s
          tempname = name
          i = 0
          while @existing_names[tempname]
            i += 1
            tempname = "#{name}_#{i}"
          end
          @existing_names[tempname] = true
          tempname
        end
      end
    end
  end
end
