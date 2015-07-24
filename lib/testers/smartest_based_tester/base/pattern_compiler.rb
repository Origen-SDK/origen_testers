require 'pathname'
module Testers
  module SmartestBasedTester
    class Base
      class PatternCompiler
        include Testers::Generator

        attr_accessor :filename

        def initialize(flow = nil)
        end

        def subroutines
          RGen.interface.referenced_subroutine_patterns
        end

        def patterns
          RGen.interface.referenced_patterns
        end
      end
    end
  end
end
