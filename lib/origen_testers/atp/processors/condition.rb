module OrigenTesters::ATP
  module Processors
    # This optimizes the condition nodes such that any adjacent flow nodes that
    # have the same condition, will be grouped together under a single condition
    # wrapper.
    #
    # For example this AST:
    #
    #   (flow
    #     (group
    #       (name "g1")
    #       (test
    #         (name "test1"))
    #       (flow-flag "bitmap" true
    #         (test
    #           (name "test2"))))
    #     (flow-flag "bitmap" true
    #       (group
    #         (name "g1")
    #         (flow-flag "x" true
    #           (test
    #             (name "test3")))
    #         (flow-flag "y" true
    #           (flow-flag "x" true
    #             (test
    #               (name "test4")))))))
    #
    # Will be optimized to this:
    #
    #   (flow
    #     (group
    #       (name "g1")
    #       (test
    #         (name "test1"))
    #       (flow-flag "bitmap" true
    #         (test
    #           (name "test2"))
    #         (flow-flag "x" true
    #           (test
    #             (name "test3"))
    #           (flow-flag "y" true
    #             (test
    #               (name "test4")))))))
    #
    class Condition < Processor
      def on_flow(node)
        extract_volatiles(node)
        node.updated(nil, optimize(process_all(node.children)))
      end

      def on_sub_flow(node)
        node.updated(nil, optimize(process_all(node.children)))
      end

      def on_group(node)
        name, *nodes = *node
        if conditions_to_remove.any? { |c| node.type == c.type && c.to_a == [name] }
          conditions_to_remove << node.updated(nil, [name])
          result = node.updated(:inline, optimize(process_all(nodes)))
          conditions_to_remove.pop
        else
          conditions_to_remove << node.updated(nil, [name])
          result = node.updated(nil, [name] + optimize(process_all(nodes)))
          conditions_to_remove.pop
        end
        result
      end

      def on_condition_node(node)
        flag, *nodes = *node
        if conditions_to_remove.any? { |c| node.type == c.type && c.to_a == [flag] }
          if volatile?(flag)
            result = node.updated(:inline, optimize(process_all(nodes)))
          else
            # This ensures any duplicate conditions matching the current one get removed
            conditions_to_remove << node.updated(nil, [flag])
            result = node.updated(:inline, optimize(process_all(nodes)))
            conditions_to_remove.pop
          end
        else
          if volatile?(flag)
            result = node.updated(nil, [flag] + optimize(process_all(nodes)))
          else
            conditions_to_remove << node.updated(nil, [flag])
            result = node.updated(nil, [flag] + optimize(process_all(nodes)))
            conditions_to_remove.pop
          end
        end
        result
      end
      OrigenTesters::ATP::Flow::CONDITION_NODE_TYPES.each do |type|
        alias_method "on_#{type}", :on_condition_node unless method_defined?("on_#{type}")
      end

      def optimize(nodes)
        results = []
        node1 = nil
        nodes.each do |node2|
          if node1
            if can_be_combined?(node1, node2)
              node1 = process(combine(node1, node2))
            else
              results << node1
              node1 = node2
            end
          else
            node1 = node2
          end
        end
        results << node1 if node1
        results
      end

      def can_be_combined?(node1, node2)
        if condition_node?(node1) && condition_node?(node2)
          !(conditions(node1) & conditions(node2)).empty?
        else
          false
        end
      end

      def condition_node?(node)
        # [:flow_flag, :run_flag, :test_result, :group, :job, :test_executed].include?(node.type)
        node.respond_to?(:type) && OrigenTesters::ATP::Flow::CONDITION_KEYS[node.type]
      end

      def combine(node1, node2)
        common = conditions(node1) & conditions(node2)
        common.each { |condition| conditions_to_remove << condition }
        node1 = process(node1)
        node1 = [node1] unless node1.is_a?(Array)
        node2 = process(node2)
        node2 = [node2] unless node2.is_a?(Array)
        common.size.times { conditions_to_remove.pop }

        node = nil
        common.reverse_each do |condition|
          if node
            node = condition.updated(nil, condition.children + [node])
          else
            node = condition.updated(nil, condition.children + node1 + node2)
          end
        end
        node
      end

      def conditions(node)
        result = []
        # if [:flow_flag, :run_flag].include?(node.type)
        if [:if_enabled, :unless_enabled, :if_flag, :unless_flag].include?(node.type)
          flag, *children = *node
          unless volatile?(flag)
            result << node.updated(nil, [flag])
          end
          result += conditions(children.first) if children.first && children.size == 1
        # elsif [:test_result, :job, :test_executed].include?(node.type)
        elsif node.type == :group
          name, *children = *node
          # Sometimes a group can have an ID
          if children.first.try(:type) == :id
            result << node.updated(nil, [name, children.shift])
          else
            result << node.updated(nil, [name])
          end
          result += conditions(children.first) if children.first && children.size == 1
        elsif OrigenTesters::ATP::Flow::CONDITION_NODE_TYPES.include?(node.type)
          flag, *children = *node
          result << node.updated(nil, [flag])
          result += conditions(children.first) if children.first && children.size == 1
        end
        result
      end

      def conditions_to_remove
        @conditions_to_remove ||= []
      end
    end
  end
end
