module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        class FlagOptimizer < ATP::Processor
          attr_reader :run_flag_table

          # Processes the AST and tabulates occurrences of unique set_run_flag nodes
          class ExtractRunFlagTable < ATP::Processor
            # Hash table of run_flag name with number of times used
            attr_reader :run_flag_table

            # Reset hash table
            def initialize
              @run_flag_table = {}
            end

            # For run_flag nodes, increment # of occurrences for specified flag
            def on_run_flag(node)
              children = node.children.dup
              name = children.shift
              state = children.shift
              unless name.is_a?(Array)
                if @run_flag_table[name.to_sym].nil?
                  @run_flag_table[name.to_sym] = 1
                else
                  @run_flag_table[name.to_sym] += 1
                end
              end
            end
          end

          # Only run this on top level flow and consider adjacent nodes, no need for
          # looking at nested conditions.
          def on_flow(node)
            # Pre-process the AST for # of occurrences of each run-flag used
            t = ExtractRunFlagTable.new
            t.process(node)
            @run_flag_table = t.run_flag_table

            name, *nodes = *node
            results = []
            node_a = nil
            nodes.each do |node_b|
              if node_a && node_a.type == :test && node_b.type == :run_flag
                result, node_a = remove_run_flag(node_a, node_b)
                results << result
              else
                results << node_a unless node_a.nil?
                node_a = node_b
              end
            end
            results << node_a unless node_a.nil?
            node.updated(nil, [name] + results)
          end

          # Given two adjacent nodes, where the first (a) is a test and the second (b)
          # is a run_flag, determine if (a) conditionally sets the same flag that (b)
          # uses.  If it does, do a logical replacement, if not, move on quietly.
          def remove_run_flag(node_a, node_b)
            on_pass = node_a.find(:on_pass)
            on_fail = node_a.find(:on_fail)

            unless on_pass.nil? && on_fail.nil?
              if on_pass.nil?
                flag_node = on_fail.find(:set_run_flag)
                conditional = [flag_node, on_fail]
              else
                flag_node = on_pass.find(:set_run_flag)
                conditional = [flag_node, on_pass]
              end
            end
            unless conditional.nil?
              children = node_b.children.dup
              name = children.shift
              # remove the '_RAN' here so it won't match and if_ran cases are ignored
              name = name.gsub(/_RAN$/, '') unless name.is_a?(Array)
              state = children.shift
              *nodes = *children
              flag_node_b = n2(:set_run_flag, name, 'auto_generated') if state == true

              if conditional.first == flag_node_b
                n = conditional.last.dup
                result = node_a.remove(n)
                n = n.remove(conditional.first) if @run_flag_table[name.to_sym] == 1
                n = n.remove(n0(:continue)) if n.type == :on_fail
                s = n.find(:set_result) if n.type == :on_fail
                n = n.remove(s) if s
                n = n.updated(nil, n.children + (nodes.is_a?(Array) ? nodes : [nodes]))
                result = result.updated(nil, result.children + (n.is_a?(Array) ? n : [n]))
                return result, nil
              end
            end
            [node_a, node_b]
          end
        end
      end
    end
  end
end
