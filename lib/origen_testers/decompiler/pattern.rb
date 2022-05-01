module OrigenTesters
  module Decompiler
    require_relative './pattern/elements/base'
    require_relative './pattern/elements/comment_block'
    require_relative './pattern/elements/frontmatter'
    require_relative './pattern/elements/pinlist'
    require_relative './pattern/elements/vector_body_element'
    require_relative './pattern/elements/vector'
    require_relative './pattern/vector_delimiter_base'
    require_relative './pattern/enumerable_ext'
    require_relative './pattern/parsers'
    require_relative './pattern/splitter'
    require_relative './pattern/spec_helpers'

    class ParseError < Origen::OrigenError
    end

    class SubclassError < Origen::OrigenError
    end

    class NoFirstVectorAvailable < Origen::OrigenError
    end

    class NoSuchSource < Origen::OrigenError
    end

    class NoSuitableDecompiler < Origen::OrigenError
    end

    class NoMethodError < Origen::OrigenError
    end

    class NoAvailableProcessor < Origen::OrigenError
    end

    class Pattern
      class << self
        attr_reader :splitter_config
        attr_reader :parser_config
        attr_reader :platform_tokens
        attr_reader :platform
        attr_reader :no_verify
      end

      attr_reader :source
      attr_reader :decompiled
      attr_reader :direct_source

      include Splitter
      include Parsers
      include EnumerableExt
      include SpecHelpers

      def initialize(source, options = {})
        options = { direct_source: false, no_verify: false }.merge(options)
        direct_source = options[:direct_source]
        no_verify = options[:no_verify]

        if source.is_a?(File)
          source = source.path
        end

        if direct_source
          @source = source
          @direct_source = true
        else
          @source = Pathname(source)
          unless @source.exist?
            message = "Cannot find pattern source '#{@source}'"
            Origen.log.error(message)
            Origen.app!.fail(exception_class: OrigenTesters::Decompiler::NoSuchSource, message: message)
          end
          @direct_source = false
        end
        @decompiled = false

        unless no_verify || self.class.no_verify
          verify_subclass_configuration
        end
      end

      def platform
        self.class.platform
      end
      alias_method :tester, :platform

      def platform?(p = nil)
        if p
          platform == p
        else
          platform == tester.name.to_s
        end
      end
      alias_method :tester?, :platform?

      def decompiler
        self.class
      end

      def decompiler?(d)
        decompiler == d
      end

      def parser_config
        self.class.parser_config || {}
      end

      def platform_tokens
        self.class.platform_tokens
      end
      alias_method :decompiler_tokens, :platform_tokens

      def comment_start
        self.class.platform_tokens[:comment_start]
      end
      alias_method :comment_token, :comment_start

      def splitter_config
        self.class.splitter_config
      end

      def method_parse_frontmatter
        if self.class.respond_to?(:parse_frontmatter)
          self.class.method(:parse_frontmatter)
        end
      end

      def method_parse_pinlist
        if self.class.respond_to?(:parse_pinlist)
          self.class.method(:parse_pinlist)
        end
      end

      def method_parse_vector
        if self.class.respond_to?(:parse_vector)
          self.class.method(:parse_vector)
        end
      end

      def verify_subclass_configuration
        if method_parse_frontmatter.nil?
          subclass_error('Missing class method #parse_frontmatter')
        elsif method_parse_pinlist.nil?
          subclass_error('Missing class method #parse_pinlist')
        elsif method_parse_vector.nil?
          subclass_error('Missing class method #parse_vector')
        elsif splitter_config.nil?
          subclass_error('Missing class variable :splitter_config')
        elsif !(Splitter::REQUIRED_KEYS - splitter_config.keys).empty?
          subclass_error("Splitter config is missing required keys: #{(Splitter::REQUIRED_KEYS - splitter_config.keys).map { |k| ':' + k.to_s }.join(', ')}")
        elsif !(splitter_config.keys - Splitter::REQUIRED_KEYS - Splitter::OPTIONAL_KEYS).empty?
          subclass_error("Splitter config contains extra keys: #{(splitter_config.keys - Splitter::REQUIRED_KEYS - Splitter::OPTIONAL_KEYS).map { |k| ':' + k.to_s }.join(', ')}")
        end
      end

      def subclass_error(message)
        Origen.log.error("#{self.class.name} failed to subclasss OrigenTesters::DecompilerPattern: #{message}")
        fail(SubclassError, "#{self.class.name} failed to subclasss OrigenTesters::DecompilerPattern: #{message}")
      end

      def decompiled?
        @decompiled
      end

      def direct_source?
        @direct_source
      end

      def first_vector
        @first_vector || begin
          each_vector do |v|
            if v.vector?
              @first_vector = v.element
              break
            end
          end
          if @first_vector.nil?
            fail OrigenTesters::Decompiler::ParseError, "Could not locate the first vector in pattern #{@source}"
          end
          @first_vector
        end
      end

      def first_timeset
        first_vector.timeset
      end
      alias_method :initial_timeset, :first_timeset

      def first_pin_states_mapped
        pins.each.with_index.with_object({}) do |(pin, i), hash|
          hash[pin] = initial_pin_states[i]
        end
      end
      alias_method :initial_pin_states_mapped, :first_pin_states_mapped

      def first_pin_states
        first_vector.pin_states
      end
      alias_method :initial_pin_states, :first_pin_states

      def pinlist_size
        pinlist.pins.size
      end
      alias_method :num_pins, :pinlist_size
      alias_method :number_of_pins, :pinlist_size

      def pins
        pinlist.pins
      end

      def decompile(options = {})
        # Read the pattern and split it into sections then parse and store the
        # frontmatter and pinlist models
        split!
        @frontmatter = _parse_frontmatter_
        @pinlist = _parse_pinlist_

        @decompiled = true
        self
      end

      def frontmatter
        @frontmatter
      end

      def pinlist
        @pinlist
      end

      def vectors
        @vector_handler ||= vector_start
      end

      def current_vector_index
        @current_vector_index
      end

      # Resolves the size of each pin in the pinlist using the initial pin states.
      # @return [Hash] Hash wherein the keys are the pin names and each value is
      #   the corresponding size.
      def pin_sizes
        # initial_pin_states.map { |pin, state| state.size }
        initial_pin_states_mapped.map { |pin, state| [pin, state.size] }.to_h
        # pins.each.with_index.with_object({}) do |(pin, i), hash|
        #  hash[pin] = initial_pin_states[i].size
        # end
      end

      def first_vector?
        first_vector
      rescue OrigenTesters::Decompiler::ParseError
        return false
      end

      # Adds any pins in the decompiled pattern to the DUT which are not already present.
      # @return [Array] Any pin names that were added to the DUT.
      def add_pins
        #        pin_sizes = pat_model.pattern_model.pin_sizes
        #        pat_model.pinlist.each_with_index do |(name, pin), i|
        #          dut.add_pin(name, size: pin_sizes[i]) unless dut.has_pin?(name)
        #        end
        retn = []
        if first_vector?
          pin_sizes.each do |pin, size|
            unless dut.has_pin?(pin)
              dut.add_pin(pin, size: size)
              retn << pin
            end
          end
        else
          fail(NoFirstVectorAvailable, "No first vector available for pattern '#{source}'. Cannot add pins to the DUT '#{dut.class.name}'")
        end
        retn
      end

      # @note <code>line</code> is this context is delimited by the given separator.
      #   This may or may not be a true newline-delimited, line.
      # def number_of_lines
      #  fail
      # end

      # Executing a pattern consist of:
      #  1. Doing some initial setup (timesets, initial pin states, etc.)
      #  2. Executing anything that can be executed in the frontmatter
      #  3. Executing the vectors 1-by-1.
      def execute(options = {})
        if Origen.tester.timeset.nil?
          if first_vector?
            Origen.tester.set_timeset(first_timeset, 40)
          else
            Origen.log.error 'No first vector available and the timeset has not already been set!'
            Origen.log.error 'Please set the timeset yourself prior to calling #execute! in a pattern that does not contain a first vector.'
            fail(NoFirstVectorAvailable, "No first vector available for pattern '#{source}'. Cannot set a timeset to execute the pattern.")
          end
        end
        frontmatter.execute!
        each_vector_with_index do |vec, i|
          if Origen.debug?
            Origen.log.info("OrigenTesters: Executing Vector #{i}")
          end
          vec.execute!
        end

        self
      end
    end
  end
end
