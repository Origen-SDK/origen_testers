module OrigenTesters
  module Test
    module Decompiler
      module Dummy
        extend OrigenTesters::Decompiler::API

        class DummyTester
          include VectorBasedTester
        end

        class PatternParsersMissing < OrigenTesters::Decompiler::Pattern
        end

        class PatternParseFrontmatterOnly < OrigenTesters::Decompiler::Pattern
          def self.parse_frontmatter(raw_frontmatter:, context:)
            OrigenTesters::Decompiler::Nodes::Frontmatter.new(context: context, pattern_header: [], comments: [])
          end
        end

        class PatternParseFrontmatterPinlist < PatternParseFrontmatterOnly
          def self.parse_pinlist(raw_pinlist:, context:)
            OrigenTesters::Decompiler::Nodes::Pinlist.new(context: context, pattern_header: [], comments: [])
          end
        end

        class PatternParseFrontmatterPinlistVector < PatternParseFrontmatterPinlist
          def self.parse_vector(raw_vector:, context:)
            OrigenTesters::Decompiler::Nodes::Vector.new(
              context:    context,
              repeat:     0,
              timeset:    'timeset',
              pin_states: %w(p1 p2),
              comment:    'Comment'
            )
          end
        end

        class Pattern < PatternParseFrontmatterPinlistVector
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

        class PatternIncomplete < PatternParseFrontmatterPinlistVector
          @platform = 'dummy_incomplete'
        end

        class PatternNoParserConfig < PatternParseFrontmatterPinlistVector
          @platform = 'pattern_no_parser_config'
          @parser_config = nil
          @splitter_config = {
            pinlist_start: 0,
            vectors_start: 0,
            vectors_end:   -1
          }
        end

        class PatternNoSplitterConfig < PatternParseFrontmatterPinlistVector
          @platform = 'pattern_no_splitter_config'
          @parser_config = {}
          @splitter_config = nil
        end

        class PatternIncompleteSplitterConfig < PatternParseFrontmatterPinlistVector
          @platform = 'pattern_incomplete_splitter_config'
          @parser_config = {}
          @splitter_config = {
            vectors_end: -1
          }
        end

        class PatternNoVerify < PatternParseFrontmatterPinlistVector
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
