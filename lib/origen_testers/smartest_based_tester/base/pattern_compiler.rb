require 'pathname'
module OrigenTesters
  module SmartestBasedTester
    class Base
      class PatternCompiler
        include OrigenTesters::Generator

        attr_accessor :filename, :part_patterns, :id

        def initialize(flow = nil)
          @part_patterns = []
        end

        def subroutines
          (references[:subroutine][:all] + references[:subroutine][:ate]).map do |p|
            p.strip.sub(/\..*/, '')
          end.uniq.sort
        end

        def patterns
          (references[:main][:all] + references[:main][:ate]).map do |p|
            p.strip.sub(/\..*/, '')
          end.uniq.sort
        end

        def references
          Origen.interface.all_pattern_references[id]
        end

        def to_be_written?
          tester.smt7?
        end
      end
    end
  end
end
