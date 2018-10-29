module OrigenTesters
  module Test
    class EmptyDUT
      include OrigenARMDebug
      include Origen::TopLevel
      include OrigenJTAG

      def initialize(options = {})
      end
    end
  end
end
