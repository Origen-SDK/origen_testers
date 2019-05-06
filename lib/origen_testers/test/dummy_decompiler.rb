module OrigenTesters
  module Test
    module Decompiler
      module Dummy
        extend OrigenTesters::Decompiler::API

        class DummyTester
          include VectorBasedTester
        end

        class Pattern < OrigenTesters::Decompiler::Pattern
          @platform = 'dummy'
          @platform_tokens = {
            comment_start: '#',
            test_token:    '!'
          }

          @splitter_config = {
            pinlist_start: 0,
            vectors_start: 0,
            vectors_end:   -1
          }

          @parser_config = {
            platform_grammar_name:        'OrigenTesters::Decompiler::BaseGrammar::VectorBased',
            include_base_tokens_grammar:  true,
            include_vector_based_grammar: true
          }
        end

        class PatternIncomplete < OrigenTesters::Decompiler::Pattern
          @platform = 'dummy_incomplete'
        end

        class PatternNoParserConfig < OrigenTesters::Decompiler::Pattern
          @platform = 'pattern_no_parser_config'
          @parser_config = nil
          @splitter_config = {}
        end

        class PatternNoSplitterConfig < OrigenTesters::Decompiler::Pattern
          @platform = 'pattern_no_splitter_config'
          @parser_config = {}
          @splitter_config = nil
        end

        class PatternIncompleteSplitterConfig < OrigenTesters::Decompiler::Pattern
          @platform = 'pattern_incomplete_splitter_config'
          @parser_config = {}
          @splitter_config = {
            vectors_end: -1
          }
        end

        class PatternNoVerify < OrigenTesters::Decompiler::Pattern
          @platform = 'pattern_no_verify'
          @no_verify = true
        end
      end

      module DummyWithDecompiler
        def self.suitable_decompiler_for(pattern: nil, tester: nil, **options)
          if pattern && (Pathname(pattern).extname == '.atp')
            OrigenTesters::IGXLBasedTester
          elsif tester && (tester == 'j750' || tester == 'uflex' || tester == 'ultraflex')
            OrigenTesters::IGXLBasedTester
          end
        end
      end

      module DummyWithDecompilerMissingMethod
      end
    end
  end
end
