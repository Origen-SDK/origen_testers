require 'set'
module OrigenTesters
  module SmartestBasedTester
    class Base
      module Processors
        # Returns an array containing all runtime control variables from the given AST node
        # and their default values
        class ExtractFlowVars < ATP::Processor
          OWNERS = [:all, :this_flow, :sub_flows]
          CATEGORIES = [:jobs, :referenced_flags, :set_flags, :set_flags_extern,
                        :referenced_enables, :set_enables]

          def run(node, options = {})
            @variables = {}
            @variables[:empty?] = true
            OWNERS.each do |t|
              @variables[t] = {}
              CATEGORIES.each { |c| @variables[t][c] = Set.new }
            end
            @sub_flow_depth = 0
            process(node)
            OWNERS.each do |t|
              CATEGORIES.each do |c|
                @variables[t][c] = @variables[t][c].to_a.sort do |x, y|
                  x = x[0] if x.is_a?(Array)
                  y = y[0] if y.is_a?(Array)
                  x <=> y
                end
              end
            end
            @variables
          end

          def on_sub_flow(node)
            @sub_flow_depth += 1
            children = node.children
            on_fail = node.find_all(:on_fail)
            children -= on_fail
            on_pass = node.find_all(:on_pass)
            children -= on_pass
            process_all(children)
            @sub_flow_depth -= 1
            process_all(on_fail)
            process_all(on_pass)
          end

          def on_if_job(node)
            add ['JOB', ''], :jobs
            process_all(node.children)
          end
          alias_method :on_unless_job, :on_if_job

          def on_if_flag(node)
            flag, *nodes = *node
            [flag].flatten.each do |f|
              add generate_flag_name(f), :referenced_flags
            end
            process_all(nodes)
          end
          alias_method :on_unless_flag, :on_if_flag

          def on_set_flag(node)
            add generate_flag_name(node.value), :set_flags
            # Also separate flags which have been set and which should be externally visible
            if !node.to_a.include?('auto_generated') || node.to_a.include?('extern')
              add generate_flag_name(node.value), :set_flags_extern
            end
          end

          def on_if_enabled(node)
            flag, *nodes = *node
            [flag].flatten.each do |f|
              add generate_flag_name(f), :referenced_enables
            end
            process_all(nodes)
          end
          alias_method :on_unless_enabled, :on_if_enabled

          def on_enable(node)
            flag = node.value.upcase
            add flag, :set_enables
          end
          alias_method :on_disable, :on_enable

          def on_set(node)
            flag = generate_flag_name(node.to_a[0])
            add flag, :set_enables
          end

          private

          def in_sub_flow?
            @sub_flow_depth > 0
          end

          def add(var, type)
            @variables[:empty?] = false
            @variables[:all][type] << var
            if in_sub_flow?
              @variables[:sub_flows][type] << var
            else
              @variables[:this_flow][type] << var
            end
          end

          def generate_flag_name(flag)
            SmartestBasedTester::Base::Flow.generate_flag_name(flag)
          end
        end
      end
    end
  end
end
