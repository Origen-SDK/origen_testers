require 'polyglot'
require 'treetop'
require_relative 'nodes'
require 'origen_testers/decompiler/base_parser'

module OrigenTesters
  module SmartestBasedTester
    module Decompiler
      class Parser
        extend OrigenTesters::Decompiler::BaseGrammar::BaseParser

        Treetop.load("#{Origen.app!.root}/lib/origen_testers/decompiler/base_grammar.treetop")
        Treetop.load("#{Origen.app!.root}/lib/origen_testers/smartest_based_tester/decompiler/avc.treetop")
        @@parser = AvcParser.new
      end
    end
  end
end
