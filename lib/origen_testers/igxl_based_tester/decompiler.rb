module OrigenTesters
  module IGXLBasedTester
    require 'origen_testers/decompiler/decompiled_pattern'
    require 'origen_testers/igxl_based_tester/decompiler/parser'

    # Currently, we are differentiating between J750 and UFLEX testers. They'll both use the same until
    # there are difference that require forking the decompiler.
    def self.decompile(pattern_file, options = {})
      decompiler(pattern_file, options).decompile
    end

    def self.decompiler(pattern_file, options = {})
      DecompiledPattern.new(pattern_file, options)
    end

    class DecompiledPattern < OrigenTesters::Decompiler::DecompiledPattern
      @parser = OrigenTesters::IGXLBasedTester::Decompiler::Parser
    end
  end
end
