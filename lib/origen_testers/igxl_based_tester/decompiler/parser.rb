require 'polyglot'
require 'treetop'
require_relative 'nodes'
require 'origen_testers/decompiler/base_parser'

module OrigenTesters
  module IGXLBasedTester
    module Decompiler
      class Parser
        extend OrigenTesters::Decompiler::BaseGrammar::BaseParser

        Treetop.load("#{Origen.app!.root}/lib/origen_testers/decompiler/base_grammar.treetop")
        Treetop.load("#{Origen.app!.root}/lib/origen_testers/igxl_based_tester/decompiler/atp.treetop")
        @@parser = AtpParser.new

        def self.extract_pinlist
          @@tree.pattern_body.vector_header.pinlist
        end

        def self.extract_vectors
          @@tree.pattern_body.vector_body.vectors
        end
      end
    end
  end
end
