module OrigenTesters
  module SmartestBasedTester
    require 'origen_testers/decompiler'
    require 'origen_testers/decompiler/pattern'
    require_relative './decompiler/nodes'
    require_relative './decompiler/processors'

    def self.suitable_decompiler_for(pattern: nil, tester: nil, **options)
      if pattern && (Pathname(pattern).extname == '.avc')
        OrigenTesters::SmartestBasedTester::Pattern
      elsif tester && tester == 'v93k'
        OrigenTesters::SmartestBasedTester::Pattern
      end
    end
    extend OrigenTesters::Decompiler::API
    register_decompiler(self)

    class Pattern < OrigenTesters::Decompiler::Pattern
      @platform = 'v93k'
      @splitter_config = {
        pinlist_start: /^FORMAT/,

        # The vectors start will be picked up right after the pinlist is parsed.
        # We'll throw away any whitespace we encounter between the pinlist and
        #   first vector element though.
        vectors_start: proc do |line:, index:, current_indices:|
          # The pinlist was encountered. Start the vectors at the next line
          # that's not just whitespace
          if current_indices[:pinlist_start] && line !~ /^\s/
            next true
          end
          false
        end,

        # V93K doesn't have any endmatter, or vector end delimiter, so just
        # grab vectors until the end of the file is reached.
        vectors_end:   -1
      }

      # The base parser with a custom AVC grammar is sufficient.
      @parser_config = {
        grammars:                           [
          "#{Origen.app!.root}/lib/origen_testers/smartest_based_tester/decompiler/avc.treetop"
        ],

        # OrigenTesters will automatically append 'Parser' from Treetop, so don't
        # need to include it here.
        platform_grammar_name:              'OrigenTesters::SmartestBasedTester::Decompiler::Avc',

        # Load the grammar for the base tokens
        include_base_tokens_grammar:        true,

        # Load the grammar for the vector_based tester base grammar
        include_vector_based_grammar:       true,

        # Create and load a custom grammar based off the 'platform_tokens' variable.
        include_platform_generated_grammar: true
      }

      # Tokens that are required both inside and outside the grammars.
      # If these are single strings or regexes, they can be put here and made
      # available both inside and outside the grammars, avoiding any pitfalls
      # with keeping this up-to-date in multiple places.
      @platform_tokens = {
        comment_start: '#'
      }

      def select_processor(node:, source:, **options)
        case node.type
          when :sequencer_instruction
            OrigenTesters::SmartestBasedTester::Decompiler::Processors::SequencerInstruction
          when :vector
            OrigenTesters::SmartestBasedTester::Decompiler::Processors::Vector
        end
      end
    end
  end
end
