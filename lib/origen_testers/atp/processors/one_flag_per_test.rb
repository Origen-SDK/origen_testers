module OrigenTesters::ATP
  module Processors
    # Ensures that all test nodes only ever set a flag once
    class OneFlagPerTest < Processor
      def run(node)
        @build_table = true
        @pass_table = {}
        @fail_table = {}
        process(node)
        @counters = {}
        @pass_table.each { |f, v| @counters[f] = 0 }
        @fail_table.each { |f, v| @counters[f] = 0 }
        @build_table = false
        process(node)
      end

      def on_test(node)
        on_pass = node.find(:on_pass)
        on_fail = node.find(:on_fail)
        if @build_table
          if on_fail
            on_fail.find_all(:set_flag).each do |n|
              @fail_table[n.to_a[0]] ||= 0
              @fail_table[n.to_a[0]] += 1
            end
          end
          if on_pass
            on_pass.find_all(:set_flag).each do |n|
              @pass_table[n.to_a[0]] ||= 0
              @pass_table[n.to_a[0]] += 1
            end
          end
        else
          to_be_set = {}
          if on_fail
            node = node.remove(on_fail)
            on_fail.find_all(:set_flag).each do |set_flag|
              old_flag = set_flag.to_a[0]
              if @fail_table[old_flag] > 1
                on_fail = on_fail.remove(set_flag)
                new_flag = "#{old_flag}_#{@counters[old_flag]}"
                @counters[old_flag] += 1
                to_be_set[old_flag] = new_flag
                c = set_flag.children.dup
                c[0] = new_flag
                set_flag = set_flag.updated(nil, c)
                on_fail = on_fail.updated(nil, on_fail.children + [set_flag])
              end
            end
            node = node.updated(nil, node.children + [on_fail])
          end
          if on_pass
            node = node.remove(on_pass)
            on_pass.find_all(:set_flag).each do |set_flag|
              old_flag = set_flag.to_a[0]
              if @pass_table[old_flag] > 1
                on_pass = on_pass.remove(set_flag)
                new_flag = "#{old_flag}_#{@counters[old_flag]}"
                @counters[old_flag] += 1
                to_be_set[old_flag] = new_flag
                c = set_flag.children.dup
                c[0] = new_flag
                set_flag = set_flag.updated(nil, c)
                on_pass = on_pass.updated(nil, on_pass.children + [set_flag])
              end
            end
            node = node.updated(nil, node.children + [on_pass])
          end
          if to_be_set.empty?
            node
          else
            nodes = to_be_set.map { |old, new| node.updated(:if_flag, [new, node.updated(:set_flag, [old, 'auto_generated'])]) }
            node.updated(:inline, [node] + nodes)
          end
        end
      end
    end
  end
end
