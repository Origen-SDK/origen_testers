Origen::Generator::Flow  # Force the original to autoload
module Origen
  class Generator
    class Flow
      alias :orig_create :create

      # Create a call stack of flows so that we can work out where the nodes
      # of the ATP AST originated from
      def create(options = {}, &block)
        OrigenTesters::Flow.callstack << caller[0].split(':').first
        orig_create(options, &block)
        OrigenTesters::Flow.callstack.pop
      end
    end
  end
end
