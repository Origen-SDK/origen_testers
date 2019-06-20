require 'colored'
module OrigenTesters::ATP
  module Formatters
    # Outputs the given AST to something resembling an ATE datalog,
    # this can optionally be rendered to a file or the console (the default).
    class Datalog < Formatter
      def on_flow(node)
        str = 'Number'.ljust(15)
        str += 'Result'.ljust(9)
        str += 'Name'.ljust(55)
        str += 'Pattern'.ljust(55)
        str += 'ID'
        puts str
        process_all(node.children)
      end

      def on_test(node)
        str = "#{node.find(:number).try(:value)}".ljust(15)
        if node.find(:failed)
          str += 'FAIL'.ljust(9).red
        else
          str += 'PASS'.ljust(9)
        end
        if n = node.find(:name)
          name = n.value
        else
          name = node.find(:object).value['Test']
        end
        str += "#{name}".ljust(55)
        str += "#{node.find(:object).value['Pattern']}".ljust(55)
        str += "#{node.find(:id).value}"
        puts str
      end

      def on_render(node)
        puts '************ Directly rendered flow snippet ************'
        puts node.value
        puts '********************************************************'
      end

      def on_log(node)
        puts "// #{node.value}"
      end

      def on_set_result(node)
        bin = node.find(:bin).try(:value)
        sbin = node.find(:softbin).try(:value)
        desc = node.find(:description).try(:value)

        if node.to_a[0] == 'pass'
          str = "               PASS     #{bin}      #{sbin}"
          color = :green
        else
          str = "               FAIL     #{bin}      #{sbin}"
          color = :red
        end
        str += "      (#{desc})" if desc

        puts '---------------------------------------------------------------------------------------------------------------------------------------------------------'
        puts str.send(color)
        puts '---------------------------------------------------------------------------------------------------------------------------------------------------------'
      end
    end
  end
end
