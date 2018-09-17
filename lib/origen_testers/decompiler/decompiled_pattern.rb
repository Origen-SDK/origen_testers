module OrigenTesters
  module Decompiler
    # The DecompiledPattern class is a base class for handling decompiled patterns.
    # The work of actually decompiling the pattern is handled by the various decompilers, but those should return
    # either an instance of this class or a child of this class.
    # Caution: do not simply reopen this class to account for a single decompiler as that could have adverse effects
    # on other decompiler
    class DecompiledPattern
      attr_reader :pattern_file
      attr_reader :pattern_model

      def initialize(pattern_file, options = {})
        # Check that the filename exists, is readable, and is in a known format.
        # fail "Could not find pattern file '#{filename}'"
        # fail "Found filename '#{filename}', but it is not readable!"
        # fail "OrigenTesters' reverse compile does not recognize file type '#{ext}'"
        @pattern_file = pattern_file
        @options = options.clone
        @decompiled = false
        @parser_class = options[:parser_class]

        @pattern_fields = [
          :pinlist, :vectors, :timesets
        ]
      end

      def inspect
        tree.inspect
      end
      alias_method :pretty_print, :inspect

      def decompiled?
        @decompiled
      end

      def decompile
        # We'll be expecting a hash with at least the following: the pinlist, in order that they appear, and an array of vectors, again, in the order that they appear.
        # It is the tester-specific decompiler's job to hand this information back to the base decompiler.
        # @pattern_model = select_decompiler.decompile

        # @decompiled = true
      end

      def pinlist
        @pinlist
      end

      def timesets
      end

      def vectors
        @vectors
      end

      def each_vector
      end

      def each
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
