module OrigenTesters
  module SmartestBasedTester
    class Base
      class ShmooTests
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
          shmoo = platform::ShmooTest.new(name, options)
          @collection << shmoo
          shmoo
        end
        alias_method :run, :add
        alias_method :run_and_branch, :add

        def platform
          Origen.interface.platform
        end

        def finalize
          # match any formatting difference between test suite shmoo and test flow shmoo
          @collection.each do |shmoo_test|
            shmoo_test.targets.each_with_index do |target, i|
              target_is_a_test_suite = false
              flow.test_suites.sorted_collection.each do |suite|
                if suite.name.to_s == target.to_s
                  target_is_a_test_suite = true
                  break
                end
              end

              unless target_is_a_test_suite
                target_is_a_test_flow = false
                flow.sub_flows.each do |name, path|
                  target_name = target.to_s.gsub(' ', '_')
                  if name.to_s.downcase == target_name.to_s.downcase
                    target_is_a_test_flow = true
                    shmoo_test.targets[i] = name
                    break
                  end
                end

                unless target_is_a_test_flow
                  fail "Shmoo test target '#{target}' for shmoo test '#{shmoo_test.name}' not found in test suites or sub_flows"
                end
              end
            end
          end
        end

        def sorted_collection
          @collection.sort_by { |st| st.name.to_s }
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
