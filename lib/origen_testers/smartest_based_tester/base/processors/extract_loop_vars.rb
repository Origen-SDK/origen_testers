require 'set'
module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        # Extracts variables that are set within a specific loop node's children.
        # This is used to determine which variables need to be re-initialized at the
        # start of each loop iteration.
        class ExtractLoopVars < ATP::Processor
          def run(loop_node)
            @loop_vars = {
              set_flags: Set.new,
              set_enables: Set.new,
              unset_flags: Set.new,
              add_flags: Set.new
            }
            # Process only the children of the loop node (not the loop parameters)
            # The loop node structure is: [:start, :stop, :step, :var, :test_inc, ...children]
            # We need to skip the first 5 elements
            start, stop, step, loop_var, test_inc, *children = *loop_node
            process_all(children)
            
            # Convert sets to sorted arrays for consistent output
            result = {}
            @loop_vars.each do |key, set|
              result[key] = set.to_a.sort
            end
            result
          end

          def on_set_flag(node)
            @loop_vars[:set_flags] << generate_flag_name(node.value)
          end

          def on_unset_flag(node)
            @loop_vars[:unset_flags] << generate_flag_name(node.value)
          end

          def on_add_flag(node)
            @loop_vars[:add_flags] << generate_flag_name(node.value)
          end

          def on_enable(node)
            @loop_vars[:set_enables] << node.value.upcase
          end
          alias_method :on_disable, :on_enable

          def on_set(node)
            @loop_vars[:set_enables] << generate_flag_name(node.to_a[0])
          end

          private

          def generate_flag_name(flag)
            SmartestBasedTester::Base::Flow.generate_flag_name(flag)
          end
        end
      end
    end
  end
end
