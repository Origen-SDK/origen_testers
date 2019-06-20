module OrigenTesters::ATP
  module Processors
    # This combines adjacent if flag nodes where the flag is in the opposite state
    #
    #   s(:flow,
    #     s(:name, "prb1"),
    #     s(:if_flag, "SOME_FLAG",
    #       s(:test,
    #         s(:name, "test1"))),
    #     s(:unless_flag, "SOME_FLAG",
    #       s(:test,
    #         s(:name, "test2"))))
    #
    #   s(:flow,
    #     s(:name, "prb1"),
    #     s(:if_flag, "SOME_FLAG",
    #       s(:test,
    #         s(:name, "test1"))),
    #       s(:else,
    #         s(:test,
    #           s(:name, "test2"))))
    #
    # See here for an example of the kind of flow level effect it has:
    # https://github.com/Origen-SDK/origen_testers/issues/43
    class AdjacentIfCombiner < OrigenTesters::ATP::Processor
      class SetRunFlagFinder < OrigenTesters::ATP::Processor
        def contains?(node, flag_name)
          @result = false
          @flag_name = flag_name
          process_all(node)
          @result
        end

        def on_set_flag(node)
          if node.to_a[0] == @flag_name
            @result = true
          end
        end
        alias_method :on_enable, :on_set_flag
        alias_method :on_disable, :on_set_flag
      end

      def on_flow(node)
        extract_volatiles(node)
        name, *nodes = *node
        node.updated(nil, [name] + optimize(process_all(nodes)))
      end

      def on_named_collection(node)
        name, *nodes = *node
        node.updated(nil, [name] + optimize(process_all(nodes)))
      end
      alias_method :on_group, :on_named_collection
      alias_method :on_sub_flow, :on_named_collection

      def on_unnamed_collection(node)
        node.updated(nil, optimize(process_all(node.children)))
      end
      alias_method :on_on_fail, :on_unnamed_collection
      alias_method :on_on_pass, :on_unnamed_collection

      def optimize(nodes)
        results = []
        node1 = nil
        nodes.each do |node2|
          if node1
            if opposite_flag_states?(node1, node2) && safe_to_combine?(node1, node2)
              results << combine(node1, node2)
              node1 = nil
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

      def combine(node1, node2)
        node1.updated(nil, process_all(node1.children) + [node2.updated(:else, process_all(node2.to_a[1..-1]))])
      end

      def opposite_flag_states?(node1, node2)
        ((node1.type == :if_flag && node2.type == :unless_flag) || (node1.type == :unless_flag && node2.type == :if_flag) ||
         (node1.type == :if_enabled && node2.type == :unless_enabled) || (node1.type == :unless_enabled && node2.type == :if_enabled)) &&
          node1.to_a[0] == node2.to_a[0]
      end

      def safe_to_combine?(node1, node2)
        # Nodes won't be collapsed if node1 touches the shared run flag, i.e. if there is any chance
        # that by the time it would naturally execute node2, the flag could have been changed by node1
        (!volatile?(node1.to_a[0]) || (volatile?(node1.to_a[0]) && !node1.contains?(:test))) &&
          !SetRunFlagFinder.new.contains?(node1, node1.to_a[0])
      end
    end
  end
end
