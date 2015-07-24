require 'pathname'
module OrigenTesters
  module SmartestBasedTester
    class Base
      class PatternCompiler
        include OrigenTesters::Generator

        attr_accessor :filename

        def initialize(flow = nil)
        end

        def subroutines
          Origen.interface.referenced_subroutine_patterns
        end

        def patterns
          Origen.interface.referenced_patterns
        end
      end
    end
  end
end
