module OrigenTesters::ATP
  module Formatters
    # Returns the executed flow as a string of test names. This
    # is mainly intended to be used for testing the runner.
    class Basic < Formatter
      def format(node, options = {})
        @output = ''
        process(node)
        @output
      end

      def on_test(node)
        if node.find(:name)
          @output += node.find(:name).value
        else
          obj = node.find(:object).value
          obj = obj['Test'] unless obj.is_a?(String)
          @output += obj
        end
        @output += ' F' if node.find(:failed)
        @output += "\n"
      end

      def on_set_result(node)
        @output += node.to_a[0].upcase
        @output += " #{node.find(:bin).value}" if node.find(:bin)
        @output += " #{node.find(:softbin).value}" if node.find(:softbin)
        @output += "\n"
      end
    end
  end
end
