module OrigenTesters::ATP
  module Processors
    # This removes on_pass/fail operations from groups and applies them to all
    # contained tests
    class ApplyPostGroupActions < Processor
      def run(node)
        @on_pass = []
        @on_fail = []
        process(node)
      end

      def on_group(node)
        on_pass = node.find(:on_pass)
        on_fail = node.find(:on_fail)
        @on_pass << on_pass
        @on_fail << on_fail
        node = node.remove(on_pass) if on_pass
        node = node.remove(on_fail) if on_fail
        node = node.updated(nil, process_all(node.children))
        @on_fail.pop
        @on_pass.pop
        node
      end

      def on_test(node)
        node = node.ensure_node_present(:on_pass) if @on_pass.any? { |n| n }
        node = node.ensure_node_present(:on_fail) if @on_fail.any? { |n| n }
        node.updated(nil, process_all(node.children))
      end

      def on_on_pass(node)
        @on_pass.each do |on_pass|
          if on_pass
            node = node.updated(nil, node.children + process_all(on_pass.children))
          end
        end
        node
      end

      def on_on_fail(node)
        @on_fail.each do |on_fail|
          if on_fail
            node = node.updated(nil, node.children + process_all(on_fail.children))
          end
        end
        node
      end
    end
  end
end
