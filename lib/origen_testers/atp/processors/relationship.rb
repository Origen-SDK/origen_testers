module OrigenTesters::ATP
  module Processors
    # This processor will apply the relationships between tests, e.g. if testB should only
    # execute if testA passes, then this processor will update the AST to make testA set
    # a flag on pass, and then update testB to only run if that flag is set.
    class Relationship < Processor
      # Returns a hash containing the IDs of all tests that have dependents
      attr_reader :test_results

      # Extracts all test-result nodes from the given AST
      class ExtractTestResults < Processor
        attr_reader :results

        def on_if_failed(node)
          ids, *children = *node
          unless ids.is_a?(Array)
            ids = [ids]
          end
          ids.each do |id|
            results[id] ||= {}
            results[id][:failed] = true
          end
          process_all(children)
        end
        alias_method :on_if_any_failed, :on_if_failed
        alias_method :on_if_all_failed, :on_if_failed

        def on_if_passed(node)
          ids, *children = *node
          unless ids.is_a?(Array)
            ids = [ids]
          end
          ids.each do |id|
            results[id] ||= {}
            results[id][:passed] = true
          end
          process_all(children)
        end
        alias_method :on_if_any_passed, :on_if_passed
        alias_method :on_if_all_passed, :on_if_passed

        def on_if_ran(node)
          id, *children = *node
          results[id] ||= {}
          results[id][:ran] = true
          process_all(children)
        end
        alias_method :on_unless_ran, :on_if_ran

        def results
          @results ||= {}.with_indifferent_access
        end
      end

      def run(node)
        t = ExtractTestResults.new
        t.process(node)
        @test_results = t.results || {}
        process(node)
      end

      def add_pass_flag(id, node)
        node = node.ensure_node_present(:on_pass)
        node = node.ensure_node_present(:on_fail)
        node.updated(nil, node.children.map do |n|
          if n.type == :on_pass
            n = n.add node.updated(:set_flag, ["#{id}_PASSED", :auto_generated])
          elsif n.type == :on_fail
            delayed = n.find(:delayed)
            if delayed && delayed.to_a[0]
              n
            else
              n.ensure_node_present(:continue)
            end
          else
            n
          end
        end)
      end

      def add_fail_flag(id, node)
        node = node.ensure_node_present(:on_fail)
        node.updated(nil, node.children.map do |n|
          if n.type == :on_fail
            n = n.add node.updated(:set_flag, ["#{id}_FAILED", :auto_generated])
            delayed = n.find(:delayed)
            if delayed && delayed.to_a[0]
              n
            else
              n.ensure_node_present(:continue)
            end
          else
            n
          end
        end)
      end

      def add_ran_flags(id, node)
        set_flag = node.updated(:set_flag, ["#{id}_RAN", :auto_generated])
        # For a group, set a flag immediately upon entry to the group to signal that
        # it ran to later tests, this is better than doing it immediately after the group
        # in case it was bypassed
        if node.type == :group || node.type == :sub_flow
          nodes = node.to_a.dup
          pre_nodes = []
          while [:name, :id, :path].include?(nodes.first.try(:type))
            pre_nodes << nodes.shift
          end
          node.updated(nil, pre_nodes + [set_flag] + nodes)

        # For a test, set a flag immediately after the referenced test has executed
        # but don't change its pass/fail handling
        elsif node.type == :test
          node.updated(:inline, [node, set_flag])
        else
          fail "Don't know how to add ran flag to #{node.type}"
        end
      end

      # Set flags depending on the result on tests which have dependents later
      # in the flow
      def on_test(node)
        node = node.updated(nil, process_all(node.children))
        nid = id(node)
        # If this test has a dependent
        if test_results[nid]
          node = add_pass_flag(nid, node) if test_results[nid][:passed]
          node = add_fail_flag(nid, node) if test_results[nid][:failed]
          node = add_ran_flags(nid, node) if test_results[nid][:ran]
        end
        node
      end
      alias_method :on_group, :on_test
      alias_method :on_sub_flow, :on_test

      def on_if_failed(node)
        id, *children = *node
        node.updated(:if_flag, [id_to_flag(id, 'FAILED')] + process_all(children))
      end
      alias_method :on_if_any_failed, :on_if_failed

      def on_if_all_failed(node)
        ids, *children = *node
        ids.reverse_each.with_index do |id, i|
          if i == 0
            node = node.updated(:if_flag, [id_to_flag(id, 'FAILED')] + process_all(children))
          else
            node = node.updated(:if_flag, [id_to_flag(id, 'FAILED'), node])
          end
        end
        node
      end

      def on_if_passed(node)
        id, *children = *node
        node.updated(:if_flag, [id_to_flag(id, 'PASSED')] + process_all(children))
      end
      alias_method :on_if_any_passed, :on_if_passed

      def on_if_all_passed(node)
        ids, *children = *node
        ids.reverse_each.with_index do |id, i|
          if i == 0
            node = node.updated(:if_flag, [id_to_flag(id, 'PASSED')] + process_all(children))
          else
            node = node.updated(:if_flag, [id_to_flag(id, 'PASSED'), node])
          end
        end
        node
      end

      def on_if_ran(node)
        id, *children = *node
        node.updated(:if_flag, [id_to_flag(id, 'RAN')] + process_all(children))
      end

      def on_unless_ran(node)
        id, *children = *node
        node.updated(:unless_flag, [id_to_flag(id, 'RAN')] + process_all(children))
      end

      # Returns the ID of the give test node (if any), caller is responsible
      # for only passing test nodes
      def id(node)
        if n = node.children.find { |c| c.type == :id }
          n.children.first
        end
      end

      def id_to_flag(id, type)
        if id.is_a?(Array)
          id.map { |i| "#{i}_#{type}" }
        else
          "#{id}_#{type}"
        end
      end
    end
  end
end
