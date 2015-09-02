module OrigenTesters
  module SmartestBasedTester
    class Base
      class Flow
        include OrigenTesters::Generator
        include OrigenTesters::Generator::FlowControlAPI

        attr_accessor :test_suites, :test_methods, :pattern_master

        def subdirectory
          'testflow'
        end

        def filename
          super.gsub('_flow', '')
        end

        def finalize(options = {})
          super
          flow_control_variables.uniq!
          collection.each { |n| n.finalize if n.respond_to?(:finalize) }
          test_suites.finalize
          test_methods.finalize
        end

        # Convenience method that will automatically generate a run and branch if a :bin
        # option is supplied. If no :bin option is present then it will generate a simple
        # run entry in the flow.
        def test(test_suite, options = {})
          sbin = options[:sbin] || options[:softbin] || options[:soft_bin]
          if (options[:bin] || sbin) && !options[:continue]
            node = run_and_branch(test_suite, options)
            options.delete(:id)
            # Only pass options to configure the bin, don't pass flow control options, those apply to the main
            # test only in this case
            bin = bad_bin(options[:bin], options.slice(*(FlowNode::ATTRS[:bad_bin].keys + FlowNode::ALIASES[:bad_bin].keys)))
            node.else_nodes << bin
            node
          else
            run(test_suite, options)
          end
        end

        # This module contains methods that correspond to the test flow primitives available
        # in the palette window of the test flow editor
        module Palette
          def run(test_suite, options = {})
            add(:run, { test_suite: test_suite }.merge(options))
          end
          alias_method :run_test, :run

          def run_and_branch(test_suite, options = {})
            add(:run_and_branch, { test_suite: test_suite }.merge(options))
          end

          def good_bin(number, options = {})
            add(:good_bin, { bin: number }.merge(options))
          end

          def bad_bin(number, options = {})
            add(:bad_bin, { bin: number }.merge(options))
          end

          def multi_bin(number, options = {})
            fail 'V93K Flow#multi_bin method has not been implemented yet!'
          end

          def print(msg, options = {})
            add(:print, { value: msg }.merge(options))
          end

          def print_to_datalog(msg, options = {})
            add(:print_to_datalog, { value: msg }.merge(options))
          end

          def assign_value(variable, value, options = {})
            add(:assign_value, { variable: variable, value: value }.merge(options))
          end

          def if_then(condition, options = {})
            add(:if_then, { condition: condition }.merge(options))
          end

          def group(name, options = {})
            name = make_unique(:group, name)
            g = add(:group, { name: name }.merge(options))
            if block_given?
              open_groups << g
              yield g
              open_groups.pop
            end
            g
          end
        end
        include Palette

        # Convenience method to provide similar functionality to enabling a Teradyne flow word/variable
        def enable_flow_word(variable, options = {})
          assign_value(variable, 1, options)
        end

        def skip(identifier = nil, options = {})
          identifier, options = nil, identifier if identifier.is_a?(Hash)
          open_skips << []
          yield
          nodes = open_skips.pop
          s = if_then(:skip, options)
          s.else_nodes = nodes
        end

        def hardware_bin_descriptions
          @hardware_bin_descriptions ||= {}
        end

        def flow_control_variables
          @flow_control_variables ||= []
        end

        private

        def add(type, options = {})
          options = save_context(options) if [:run, :run_and_branch].include?(type)

          # Delete the ID if a test within a group with the same ID to avoid a duplicate ID
          # error.
          if options[:id]
            id = Origen.interface.filter_id(options[:id], options)
            options.delete(:id) if group_opened? && open_groups.any? { |g| g.id == id }
          end
          node = track_relationships(options) do |options|
            platform::FlowNode.create(self, type, options)
          end
          unless Origen.interface.resources_mode?
            if skip_opened?
              open_skips.last << node
              node.parent = open_skips.last
            else
              if group_opened?
                open_groups.last.nodes << node
                node.parent = open_groups.last.nodes
              else
                collection << node
              end
            end
          end
          if node.test?
            node.test_suite = options[:test_suite]
            c = Origen.interface.consume_comments
            unless Origen.interface.resources_mode?
              Origen.interface.descriptions.add_for_test_usage(node.test_suite.name, Origen.interface.top_level_flow, c)
            end
          else
            Origen.interface.discard_comments
          end
          node
        end

        def open_skips
          @open_skips ||= []
        end

        def skip_opened?
          open_skips.size > 0
        end

        def open_groups
          @open_groups ||= []
        end

        def group_opened?
          open_groups.size > 0
        end

        def make_unique(type, name, options = {})
          @uniques ||= {}
          t = @uniques[type] ||= {}
          t[name] ||= 0
          t[name] += 1
          if t[name] == 1
            name
          else
            "#{name}_#{t[name]}"
          end
        end
      end
    end
  end
end
