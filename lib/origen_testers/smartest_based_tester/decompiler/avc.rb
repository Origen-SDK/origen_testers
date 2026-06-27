module OrigenTesters
  module SmartestBasedTester
    class Pattern
      require_relative './nodes'

      module Avc
        def nodes_namespace
          OrigenTesters::SmartestBasedTester::Decompiler::Avc
        end

        def parse_frontmatter(raw_frontmatter:, context:)
          # So far, only seen patterns that have comments and/or whitespace in
          # the frontmatter. Not sure if anything else is allowed.
          # For this, every comment will be considered the 'header'
          header = []
          raw_frontmatter.each_with_index do |l, i|
            if !(l =~ Regexp.new('^\s*#')).nil?
              header << l.chomp
            elsif l.strip.empty?
              # Whitespace. Do nothing.
            else
              Origen.app!.fail!("Unable to parse pattern frontmatter, at line: #{i}")
            end
          end
          OrigenTesters::Decompiler::Nodes::Frontmatter.new(context:        context,
                                                            pattern_header: header,
                                                            comments:       [])
        end

        def parse_pinlist(raw_pinlist:, context:)
          raw_pinlist = raw_pinlist.join('')
          # The pinlist can be parsed by grabbing everything between the 'format' token and the ';'
          # character then splitting by whitespace. Whitespace is then stripped to clean
          # up the names.
          # E.g.: FORMAT TCLK TDI TDO TMS;
          OrigenTesters::Decompiler::Nodes::Pinlist.new(context: context,
                                                        pins:    raw_pinlist[raw_pinlist.index('FORMAT')..raw_pinlist.index(';') - 1].split(/\s+/)[1..-1].map(&:strip))
        end

        def parse_vector(raw_vector:, context:, meta:)
          if raw_vector =~ Regexp.new('^\s*#')
            # Comment
            OrigenTesters::Decompiler::Nodes::CommentBlock.new(context:  context,
                                                               comments: raw_vector.split("\n"))
          elsif raw_vector =~ Regexp.new('^R\d+\s')
            # Vector
            elements = raw_vector.split(/\s+/, 2 + context.pinlist.size)
            elements[-1] = elements[-1].split(/\s/, 2)
            elements[-1][0] = elements[-1][0].gsub(';', '').chomp
            elements[-1][1] = elements[-1][1].gsub(';', '').chomp

            nodes_namespace::Vector.new(context:    context,
                                        repeat:     elements[0].gsub('R', '').to_i,
                                        timeset:    elements[1],
                                        pin_states: (elements[2..-2] || []) << elements[-1][0],
                                        comment:    elements[-1][1])
          else
            # Anything that doesn't start with Rxyz where xyz is some integer
            # will be considered a sequencer instruction
            inst_plus_args = raw_vector.split(/\s+/)
            inst_plus_args.last.gsub!(';', '').strip!

            nodes_namespace::SequencerInstruction.new(context:     context,
                                                      instruction: inst_plus_args[0],
                                                      arguments:   inst_plus_args[1..-1])
          end
        end
      end
    end
  end
end
