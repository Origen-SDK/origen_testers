module OrigenTesters
  module IGXLBasedTester
    class Pattern
      require_relative './nodes'

      module Atp
        def nodes_namespace
          OrigenTesters::IGXLBasedTester::Decompiler::Atp
        end

        def parse_frontmatter(raw_frontmatter:, context:)
          in_header = true
          header = []
          comments = []
          variable_assignments = {}
          imports = {}
          raw_frontmatter.each_with_index do |l, i|
            if l =~ Regexp.new('^\s*//')
              if in_header
                # Header Comment
                header << l.chomp
              else
                # Other Comment
                comments << l.chomp
              end
            elsif !(l =~ Regexp.new(/=/)).nil?
              # Variable Assignment
              var, val = l.split('=').map(&:strip)
              variable_assignments[var] = val.gsub(';', '')
            elsif !(l =~ Regexp.new(/import/)).nil?
              # Import
              import, type, val = l.split(/\s+/)
              imports[val.gsub(';', '')] = type
            elsif l.strip.empty?
              # Just whitespace. Ignore this, but don't throw an error
            elsif !(l =~ Regexp.new(/vector/)).nil?
              # Line break between vector keyword and pinlist, ignore
            else
              Origen.app!.fail!("Unable to parse pattern frontmatter, at line: #{i}")
            end
          end
          nodes_namespace::Frontmatter.new(context:              self,
                                           pattern_header:       header,
                                           variable_assignments: variable_assignments,
                                           imports:              imports,
                                           comments:             comments
                                          )
        end

        def parse_pinlist(raw_pinlist:, context:)
          raw_pinlist = raw_pinlist.join('')
          OrigenTesters::Decompiler::Nodes::Pinlist.new(context: self,
                                                        pins:    raw_pinlist[raw_pinlist.index('$') + 1..raw_pinlist.index(')') - 1].split(/,\s*/)[1..-1]
                                                       )
        end

        def parse_vector(raw_vector:, context:, meta:)
          if raw_vector =~ Regexp.new('^\s*//')
            nodes_namespace::CommentBlock.new(context:  self,
                                              comments: raw_vector.split("\n")
                                             )
          elsif raw_vector =~ Regexp.new('^\s*start_label')
            nodes_namespace::StartLabel.new(context:     self,
                                            start_label: raw_vector[raw_vector.index('start_label') + 11..-1].strip[0..-2]
                                           )
          elsif raw_vector =~ Regexp.new('^\s*global')
            contents = raw_vector.strip['global'.size + 1..-2].strip.split(/\s+/)
            nodes_namespace::GlobalLabel.new(context:    self,
                                             label_type: contents[0],
                                             label_name: contents[1]
                                            )
          elsif raw_vector =~ Regexp.new(':(?!(.*>))')
            nodes_namespace::Label.new(context:    self,
                                       # Strip any whitespace from the vector and grab contents up to
                                       # the ':' symbol.
                                       label_name: raw_vector.strip[0..-2]
                                      )
          else

            opcode_plus_args = raw_vector[0..(raw_vector.index('>') - 1)].rstrip.split(/\s+/)
            timeset_plus_pins = raw_vector[(raw_vector.index('>') + 1)..(raw_vector.index(';') - 1)].strip.split(/\s+/)
            nodes_namespace::Vector.new(context:          self,
                                        timeset:          timeset_plus_pins[0],
                                        pin_states:       timeset_plus_pins[1..-1],
                                        opcode:           (opcode_plus_args[0] && opcode_plus_args[0].empty?) ? nil : opcode_plus_args[0],
                                        opcode_arguments: opcode_plus_args[1..-1],
                                        comment:          begin
                if raw_vector =~ Regexp.new('//')
                  raw_vector[raw_vector.index('//') + 2..-1].strip
                else
                  ''
                end
              end
                                       )
          end
        end
      end
    end
  end
end
