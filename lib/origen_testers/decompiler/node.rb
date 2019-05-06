require 'ast'

module OrigenTesters
  module Decompiler
    class Node < ::AST::Node
      attr_reader :input, :interval, :file, :number_of_lines
    end
  end
end
