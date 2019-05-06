module OrigenTesters
  module IGXLBasedTester
    # Currently, we aren't differentiating between J750 and UFLEX testers. They'll both use the same until
    # there are difference that require forking the decompiler.
    require 'origen_testers/decompiler'
    require 'origen_testers/decompiler/pattern'
    require_relative './decompiler/nodes'
    require_relative './decompiler/processors'

    def self.suitable_decompiler_for(pattern: nil, tester: nil, **options)
      if pattern && (Pathname(pattern).extname == '.atp')
        OrigenTesters::IGXLBasedTester::Pattern
      elsif tester && (tester == 'j750' || tester == 'uflex' || tester == 'ultraflex')
        OrigenTesters::IGXLBasedTester::Pattern
      end
    end
    extend OrigenTesters::Decompiler::API
    register_decompiler(self)

    class Pattern < OrigenTesters::Decompiler::Pattern
      @platform = 'j750'
      @splitter_config = {
        pinlist_start:              /^vector/,
        vectors_start:              /^{/,
        vectors_end:                /^}/,
        vectors_include_start_line: false,
        vectors_include_end_line:   false
      }

      # Tokens that are required both inside and outside the grammars.
      # If these are single strings or regexes, they can be put here and made
      # available both inside and outside the grammars, avoiding any pitfalls
      # with keeping this up-to-date in multiple places.
      @platform_tokens = {
        comment_start: '//'
      }

      @parser_config = {
        grammars:                           [
          "#{Origen.app!.root}/lib/origen_testers/igxl_based_tester/decompiler/atp.treetop"
        ],

        # OrigenTesters will automatically append 'Parser' from Treetop, so don't
        # need to include it here.
        platform_grammar_name:              'OrigenTesters::IGXLBasedTester::Decompiler::Atp',

        # Load the grammar for the base tokens
        include_base_tokens_grammar:        true,

        # Load the grammar for the vector_based tester base grammar
        include_vector_based_grammar:       true,

        # Create and load a custom grammar based off the 'platform_tokens' variable.
        include_platform_generated_grammar: true
      }

      def select_processor(node:, source:, **options)
        case node.type
          when :start_label
            OrigenTesters::IGXLBasedTester::Decompiler::Processors::StartLabel
          when :vector
            OrigenTesters::IGXLBasedTester::Decompiler::Processors::Vector
          when :global_label
            OrigenTesters::IGXLBasedTester::Decompiler::Processors::GlobalLabel
          when :label
            OrigenTesters::IGXLBasedTester::Decompiler::Processors::Label
        end
      end
    end
  end
end
