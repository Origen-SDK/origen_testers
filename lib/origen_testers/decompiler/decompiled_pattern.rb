module OrigenTesters
  module Decompiler
    # The DecompiledPattern class is a base class for handling decompiled patterns.
    # The work of actually decompiling the pattern is handled by the various decompilers, but those should return
    # either an instance of this class or a child of this class.
    # Caution: do not simply reopen this class to account for a single decompiler as that could have adverse effects
    # on other decompiler
    class DecompiledPattern
      attr_reader :input
      attr_reader :pattern_model
      attr_reader :options

      class << self
        attr_reader :parser
      end

      def initialize(input, decompiler: nil, raw_input: false, **options)
        @input = input
        @options = options.clone
        @decompiled = false
        @raw_input = raw_input

        if input.is_a?(Pathname)
          Origen.app.fail!(message: "Decompiler: Could not locate pattern source at #{input}") unless input.exist?
        elsif !raw_input
          Origen.app.fail!(message: "Decompiler: Could not locate pattern source at #{input}") unless File.file?(input)
        end
      end

      def decompile
        self.class.parser.parse begin
          if raw_input?
            input
          elsif input.is_a?(File)
            input.read
          elsif input.is_a?(Pathname)
            File.open(input.to_s, 'r').read
          else
            File.open(input, 'r').read
          end
        end
        @pattern_model = self.class.parser.tree

        @decompiled = true
        self
      end

      def inspect
        pattern_model.inspect
      end
      alias_method :pretty_print, :inspect

      def decompiled?
        @decompiled
      end

      def pinlist
        pattern_model.pinlist.pins
      end
      alias_method :pins, :pinlist

      def vectors
        pattern_model.pattern_body.vector_body.vectors
      end

      def raw_input?
        !!@raw_input
      end

      # Execute will execute/generate a pattern from the current pattern model.
      # This will use the vector_generator's push_vector method and will push it to the tester of choice.
      def execute
        # vectors.each(&:execute)
        pattern_model.execute
      end
      alias_method :generate, :execute
    end
  end
end
