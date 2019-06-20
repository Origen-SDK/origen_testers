module OrigenTesters::ATP
  module Processors
    # Removes embedded else nodes and converts them to the equivalent inverse condition
    # node at the same level as the parent node
    class ElseRemover < Processor
      def run(node)
        process(node)
      end

      def on_condition_node(node)
        if e = node.find(:else)
          n1 = node.remove(e)
          if node.type.to_s =~ /if_/
            type = node.type.to_s.sub('if_', 'unless_').to_sym
          elsif node.type.to_s =~ /unless_/
            type = node.type.to_s.sub('unless_', 'if_').to_sym
          else
            fail "Don't know how to inverse: #{node.type}"
          end
          n2 = e.updated(type, [n1.to_a[0]] + e.children)
          node.updated(:inline, [n1, n2])
        else
          node.updated(nil, process_all(node.children))
        end
      end
      OrigenTesters::ATP::Flow::CONDITION_NODE_TYPES.each do |type|
        alias_method "on_#{type}", :on_condition_node unless method_defined?("on_#{type}")
      end
    end
  end
end
