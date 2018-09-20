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
      end
    end
  end
end
