module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        # Processes the AST and tabulates occurrences of unique set_run_flag nodes
        class ExtractRunFlagTable < ATP::Processor
          # Hash table of run_flag name with number of times used
          attr_reader :run_flag_table

          # Reset hash table
          def initialize
            @run_flag_table = {}.with_indifferent_access
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
      end
    end
  end
end
