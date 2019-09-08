module OrigenTesters
  module Decompiler
    module API
      @registered_decompilers = []

      # Decompiles the given pattern, returning
      def decompile(pattern, options = {})
        decompiled_pattern(pattern, options).decompile
      end

      # @note This method is the same as #decompile except that the module's
      #   #decompile method won't be automatically called.
      def decompiled_pattern(pattern, options = {})
        # decompiler!(pattern).decompiled_pattern(pattern)
        _decompiler = options.delete(:decompiler)
        _decompiler.nil? ? decompiler!(pattern).new(pattern, options) : _decompiler.new(pattern, options)
      end

      # Creates a decompiled pattern from the raw input directly.
      # In this case, no attempts to figure out the decompiler are made. The
      # suitable decompiler should either be given with the :decompiler parameter,
      # or the current environment will be used.
      def decompile_text(text, decompiler: nil)
        if decompiler.nil?
          select_decompiler!.new(text, direct_source: true).decompile
        else
          decompiler.new(text, direct_source: true).decompile
        end
      end
      alias_method :decompile_str, :decompile_text
      alias_method :decompile_string, :decompile_text
      alias_method :decompile_raw_input, :decompile_text

      # Returns the decompiler module that will be uesd to decompile the
      # given pattern source.
      def select_decompiler(pattern = nil, options = {})
        if pattern.is_a?(Hash)
          options = pattern
          pattern = nil
        elsif pattern.nil?
          options = {}
          pattern = nil
        end

        # if respond_to?(:suitable_decompiler_for)
        # puts "HI".red
        #  puts self
        #  registered_decompilers = [self]
        # end

        _registered_decompilers = respond_to?(:suitable_decompiler_for) ? [self] : registered_decompilers

        # We have the list of modules that support decompilation, but those modules
        # could have sub-modules that support other decompilation flavors.
        # We'll select the decompiler by just iterating through each support
        # decompiler and until we find one that supports either the file extension,
        # or the current tester name.
        _registered_decompilers.each do |m|
          if pattern
            mod = m.suitable_decompiler_for(pattern: pattern, **options)
          elsif tester.nil?
            return nil
          else
            mod = m.suitable_decompiler_for(tester: Origen.tester.name.to_s, **options)
          end

          if mod
            return mod
          end
        end

        nil
      end
      alias_method :decompiler, :select_decompiler
      alias_method :decompiler_for, :select_decompiler

      def select_decompiler!(pattern = nil, options = {})
        mod = select_decompiler(pattern, options)

        if mod.nil? && pattern
          # Origen.log.error "Unknown decompiler for file extension '#{File.extname(pattern)}'"
          Origen.app!.fail(
            message:         "Cannot find a suitable decompiler for pattern source '#{pattern}' ('#{File.extname(pattern)}')",
            exception_class: OrigenTesters::Decompiler::NoSuitableDecompiler
          )
        elsif mod.nil?
          # Origen.log.error "Unknown decompiler for tester #{Origen.tester.name}"
          # fail "Current environment '#{Orige.current_environment}' does not contain a suitable decompiler! Cannot select this as the decompiler."
          Origen.app!.fail(
            message:         "Current environment '#{Origen.environment.file.basename}' does not contain a suitable decompiler! Cannot select this as the decompiler.",
            exception_class: OrigenTesters::Decompiler::NoSuitableDecompiler
          )
        end
        mod
      end
      alias_method :decompiler!, :select_decompiler!
      alias_method :decompiler_for!, :select_decompiler!

      # Returns all the registered decompiler modules.
      # @note Registered decompilers are stored on the OrigenTesters::Decompiler module.
      def registered_decompilers
        OrigenTesters::Decompiler::API.instance_variable_get(:@registered_decompilers)
      end

      # Registers a new decompiler module.
      # @return [TrueClass, FalseClass] Like Ruby's #require method, returns
      #   true if decompiler is now registered and returns false if the mod
      #   was previously registered.
      #   If there are problems registering the mod, an exception is raised.
      # @raise [NoModule]
      def register_decompiler(mod)
        if mod.is_a?(String)
          mod = eval(mod)
        end

        if registered_decompiler?(mod)
          false
        else
          verify_decompiler_mod!(mod)
          registered_decompilers << mod
          true
        end
      end

      # Verifies that the registered decompiler has the required methods
      # available. Namely: #select_decompiler and #decompiled_pattern
      def verify_decompiler_mod!(mod)
        unless mod.respond_to?(:suitable_decompiler_for)
          Origen.app!.fail(
            exception_class: OrigenTesters::Decompiler::NoMethodError,
            message:         "No method #suitable_decompiler_for found on #{mod}. Cannot register as a decompiler."
          )
        end
        true
      end

      # Queries if a decompiler is available for the given pattern.
      def decompiler_for?(pattern = nil, options = {})
        !select_decompiler(pattern, options).nil?
      end

      # Queries if the decompiler in mod has been registered.
      def registered_decompiler?(mod)
        if mod.is_a?(String)
          mod = eval(mod)
        end

        registered_decompilers.include?(mod)
      end

      def execute(pattern, options = {})
        decompile(pattern, options).execute(options)
      end

      def add_pins(pattern, options = {})
        decompile(pattern, options).add_pins
      end

      def self.convert(pattern)
      end
    end
  end
end
