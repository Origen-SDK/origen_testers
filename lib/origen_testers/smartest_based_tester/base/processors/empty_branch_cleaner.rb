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

          # Returns true if:
          #   - node is completely empty
          #   - only child is (continue) node
          #   - only two children, one continue and one set-result
          def branch_is_empty?(node)
            children = node.children.dup
            return true if children.nil?

            # test for only-child situation
            first_born = children.shift
            if children.empty?
              if first_born == n0(:continue)
                return true
              else
                return false
              end
            end

            # if only 2 children, check qualificataions, else done and return false
            next_born = children.shift
            if children.empty?
              if (first_born.type == :continue && next_born.type == :set_result) ||
                 (first_born.type == :set_result && next_born.type == :continue)
                return true
              end
            end
            false
          end
        end
      end
    end
  end
end
