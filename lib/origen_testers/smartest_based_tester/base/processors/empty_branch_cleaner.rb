module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        class EmptyBranchCleaner < ATP::Processor
          # Delete any on-fail child if it's 'empty'
          def on_test(node)
            on_pass = node.find(:on_pass)
            on_fail = node.find(:on_fail)
            unless on_fail.nil?
              n = node.remove(on_fail) if branch_is_empty?(on_fail)
              return n
            end
            node
          end
          
          # Returns true if node is completely empty or if (continue) is only child
          def branch_is_empty?(node)
            children = node.children.dup
            return true if children.nil?
            first_born = children.shift   
            return true if children.empty? && first_born == n0(:continue)
            false
          end
        end
      end
    end
  end
end
