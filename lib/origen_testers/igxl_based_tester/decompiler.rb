module OrigenTesters
  module IGXLBasedTester
  	require 'origen_testers/decompiler'
  	require 'origen_testers/igxl_based_tester/decompiler/syntax/node'
  	require 'origen_testers/igxl_based_tester/decompiler/syntax/parser'
  	
  	# Currently, we are differentiating between J750 and UFLEX testers. They'll both use the same until
  	# there are difference that require forking the decompiler.
  	def self.decompile(pattern_file, options={})
  		DecompiledPattern.new(pattern_file, options).decompile
  	end
  	
  	class DecompiledPattern < OrigenTesters::Decompiler::DecompiledPattern
  		def decompile
  			parser = OrigenTesters::IGXLBasedTester::Decompiler::Parser
  			f = File.open(pattern_file, 'r')
  			parser.parse(f.read)
  			@pinlist = parser.extract_pinlist
  			@vectors = parser.extract_vectors
  			
  			@decompiled = true
  			self
  		end
  	end
  	
  end
end
