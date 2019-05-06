module OrigenTesters
  module Decompiler
    class Parser
      attr_reader :parser
      attr_reader :parent
      attr_reader :base_tokens_grammar_file
      attr_reader :base_vector_based_grammar_file

      def initialize(parent)
        @parent = parent
        @base_tokens_grammar_file = "#{Origen.app!.root}/lib/origen_testers/decompiler/base_grammar/tokens/tokens.treetop"
        @base_vector_based_grammar_file = "#{Origen.app!.root}/lib/origen_testers/decompiler/base_grammar/vector_based/vector_based.treetop"

        load_grammars
        @parser = eval("#{config[:platform_grammar_name]}Parser.new")
      end

      def config
        parent.class.parser_config || {}
      end

      def load_grammars
        if config[:include_base_tokens_grammar]
          require "#{Origen.app.root}/lib/origen_testers/decompiler/base_grammar/tokens/nodes"
          require "#{Origen.app.root}/lib/origen_testers/decompiler/base_grammar/tokens/processors"
          load_grammar(base_tokens_grammar_file)
        end

        if config[:include_vector_based_grammar]
          require "#{Origen.app.root}/lib/origen_testers/decompiler/base_grammar/vector_based/nodes"
          require "#{Origen.app.root}/lib/origen_testers/decompiler/base_grammar/vector_based/processors"
          load_grammar(base_vector_based_grammar_file)
        end

        if config[:include_platform_generated_grammar]
          Treetop.load_from_string(generate_platform_grammar)
          eval(generate_platform_nodes)
        end

        if config[:grammars]
          config[:grammars].each { |g| load_grammar(g) }
        end
      end

      def load_grammar(grammar_file)
        Treetop.load(grammar_file)
      end

      def parse_frontmatter(raw_data)
        parse(raw_data, root: 'frontmatter')
      end

      def parse_pinlist(raw_data)
        # parse(raw_data, root: 'pinlist')
        parse(raw_data, root: 'pinlist')
      end

      def parse_vector(raw_data)
        parse(raw_data, root: 'vector_types')
      end

      def generate_platform_nodes
        platform_nodes = ["module ::#{config[:platform_grammar_name]}"]
        platform_nodes << '  module PlatformTokens'

        parent.class.platform_tokens.keys.each do |token|
          platform_nodes << "    class #{token.to_s.camelize} < Treetop::Runtime::SyntaxNode"
          platform_nodes << '    end'
        end

        platform_nodes << '  end'
        platform_nodes << 'end'
        platform_nodes.join("\n")
      end

      # Need to fix the module name here
      def generate_platform_grammar
        [
          'module OrigenTesters',
          '  module IGXLBasedTester',
          '    module Decompiler',
          '      module Atp',
          '      grammar PlatformTokens',
          '        rule comment_start',
          "          '#{parent.class.platform_tokens[:comment_start]}' <CommentStart>",
          '        end',
          '      end',
          '      end',
          '    end',
          '  end',
          'end'].join("\n")

        def spaces(num_spaces)
          ' ' * num_spaces
        end

        # Unfortanutely, Treetop can't understand full namespaces.
        # That is, ::OrigenTesters::Decompiler::... doesn't parse.
        # So, need to split this up into single modules.
        platform_grammar = []

        num_spaces = 0
        space_incr = 2
        config[:platform_grammar_name].to_s.split('::').each_with_index do |mod, i|
          platform_grammar << "#{spaces(num_spaces)}module #{mod}"
          num_spaces += space_incr
        end

        # Add the grammar namespace
        platform_grammar << "#{spaces(num_spaces)}grammar PlatformTokens"

        num_spaces += space_incr
        parent.class.platform_tokens.each do |sym, token|
          platform_grammar << "#{spaces(num_spaces)}rule #{sym}"
          platform_grammar << "#{spaces(num_spaces + space_incr)}'#{token}' <#{sym.to_s.camelize}>"
          platform_grammar << "#{spaces(num_spaces)}end"
        end
        num_spaces -= space_incr

        # Add the grammar's closing 'end' token
        platform_grammar << "#{spaces(num_spaces)}end"
        num_spaces -= space_incr

        # Add all the 'end' statements
        config[:platform_grammar_name].to_s.split('::').size.times do |t|
          platform_grammar << "#{spaces(num_spaces)}end"
          num_spaces -= space_incr
        end
        platform_grammar.join("\n")
      end

      def parse(data, root:)
        data = data.join('') if data.is_a?(Array)
        tree = parser.parse(data, root: root)

        if tree.nil?
          {
            message: parser.failure_reason,
            line:    parser.failure_line,
            column:  parser.failure_column
          }
        else
          tree.to_ast
        end
      end
    end
  end
end
