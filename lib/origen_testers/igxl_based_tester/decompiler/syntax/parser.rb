require 'polyglot'
require 'treetop' 
require_relative 'node'

module OrigenTesters
  module IGXLBasedTester
  	module Decompiler
  		
  		class Parser
				def initialize(*args)
				end
				 			
	 			Treetop.load("#{Origen.app!.root}/lib/origen_testers/igxl_based_tester/decompiler/grammar/atp.treetop")
	 			@@parser = AtpParser.new
	  		
	  		def self.parser
	  		end

				def self.parse_file
				end
				
				def self.parse(data)
          puts "PARSING!"

          data2 = <<-EOT
// ***************************************************************************
// GENERATED:
//   Time:    31-Aug-2015 03:38AM
//   By:      Stephen McGinty
//   Command: origen g delay -t debug_j750.rb
// ***************************************************************************
// ENVIRONMENT:
//   Application
//     Source:    git@github.com:Origen-SDK/origen_testers.git
//     Version:   0.5.0
//     Branch:    master(e3384c47ea4) (+local edits)
//   Origen
//     Source:    https://github.com/Origen-SDK/origen
//     Version:   0.2.4
//   Plugins
//     origen_arm_debug:         0.4.3
//     origen_jtag:              0.12.0
//     origen_swd:               0.5.0
// ***************************************************************************

import tset tp0;                                                                                
svm_only_file = no;                                                                             
opcode_mode = extended;                                                                         
compressed = yes;                                                                               
                                                                                                

vector ($tset, tclk, tdi, tdo, tms)
{
start_label pattern_st:                                                                         
//                                                                                              t t t t
//                                                                                              c d d m
//                                                                                              l i o s
//                                                                                              k      
// Wait for 40.0ms
repeat 65535                                                     > tp0                          X X X X ;
repeat 65535                                                     > tp0                          X X X X ;
repeat 65535                                                     > tp0                          X X X X ;
repeat 65535                                                     > tp0                          X X X X ;
repeat 65535                                                     > tp0                          X X X X ;
repeat 65535                                                     > tp0                          X X X X ;
repeat 65535                                                     > tp0                          X X X X ;
repeat 65535                                                     > tp0                          X X X X ;
repeat 65535                                                     > tp0                          X X X X ;
repeat 65535                                                     > tp0                          X X X X ;
repeat 11316                                                     > tp0                          X X X X ;
end_module                                                       > tp0                          X X X X ;

}                                                          
EOT
					@@tree = @@parser.parse(data)
					if @@tree.nil?
						puts "NIL TREE"
            puts @@parser.failure_reason
            puts @@parser.failure_line
            puts @@parser.failure_column
					end
					#puts tree.methods
          #puts tree.extension_modules
          #puts tree
				  #exit!
          #clean_tree(tree)
          @@tree

        end
				
        def self.clean_tree(tree)
          return if tree.nil? || tree.elements.empty?
          tree.elements.each do |n| 
            n.clean if n.respond_to?(:clean)
            clean_tree(n)
          end
          tree
        end

				def decompile
					# Get the sybolized parse tree from the input
          tree = Parser.parse("#{Origen.app.root}/approved/j750/delay.rb")
          
          # Using the parse tree, extract the needed information to recreate the pattern. Specifically, the pinlist and vectors.
          # (timesets, and other stuff may be dealt with in future PRs)

          # Extract the pinlist out of the pattern
          pinlist = tree.pattern_body.vector_header.vector_pinlist.elements.collect { |pin| pin.elements[0].vector_pin }

          # Map everything in the vector body
          vectors = tree.pattern_body.vector_body.vectors.elements.map { |e| e.to_vector }
				end
				
				def self.extract_pinlist
					@@tree.pattern_body.vector_header.vector_pinlist.elements.collect { |pin| pin.elements[0].vector_pin }
				end
				
				def self.extract_vectors
					@@tree.pattern_body.vector_body.vectors.elements
				end
  		end
  		
  	end
  end
end

