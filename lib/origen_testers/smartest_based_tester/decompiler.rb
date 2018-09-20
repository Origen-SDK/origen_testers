module OrigenTesters
  module SmartestBasedTester
    require 'origen_testers/decompiler/decompiled_pattern'
    require 'origen_testers/smartest_based_tester/decompiler/parser'

    # Currently, we aren't differentiating between J750 and UFLEX testers. They'll both use the same until
    # there are difference that require forking the decompiler.
    def self.decompile(pattern_file, options = {})
      DecompiledPattern.new(pattern_file, options).decompile
    end

    class DecompiledPattern < OrigenTesters::Decompiler::DecompiledPattern
      def decompile
        parser = OrigenTesters::SmartestBasedTester::Decompiler::Parser
        f = File.open(pattern_file, 'r')
        parser.parse(f.read)
        @pattern_model = parser.tree

        @decompiled = true
        self
      end
    end
  end
end
