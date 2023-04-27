module OrigenTesters
  module Charz
    # A Charz Profile
    # Used to store characterization routines as well as flow control, conditional execution, and test placement meta data
    class Profile
      # @!attribute id
      #   @return [Symbol] the id of the current profile, used as a key in OrigenTesters::Charz#charz_profiles hash
      # @!attribute name
      #   @return [Symbol] the value used (if the user decides) to generate the name of the created charz test. defaults to the value of @id
      # @!attribute placement
      #   @return [Symbol] placement of the to be created charz tests, defaults to inline, accepts :eof as well. Other placements can be used as well if @valid_placements is altered
      # @!attribute on_result
      #   @return [Symbol] indicates if the resulting charz tests are depending on the point tests result, valid values include :on_fail, and :on_pass
      # @!attribute enables
      #   @return [Symbol, String, Array, Hash] enable gates to be wrapped around the resulting charz tests
      # @!attribute flags
      #   @return [Symbol, String, Array, Hash] flag gates to be wrapped around the resulting charz tests
      # @!attribute routines
      #   @return [Array] list of charz routines to be called under this profile
      # @!attribute charz_only
      #   @return [Boolean] indicates if the point tests should or shouldn't be added to the flow
      attr_accessor :id, :name, :placement, :on_result, :enables, :flags, :routines, :charz_only

      def initialize(id, options, &block)
        @id = id
        @id = @id.symbolize unless id.is_a? Symbol
        options.each { |k, v| instance_variable_set("@#{k}", v) }
        (block.arity < 1 ? (instance_eval(&block)) : block.call(self)) if block_given?
        @name ||= id
        @placement ||= :inline
        @defined_routines = options.delete(:defined_routines)
        attrs_ok?
      end

      def attrs_ok?
        return if @quality_check == false

        unless @routines.is_a?(Array)
          Origen.log.error "Profile #{id}: routines is expected to be of type <Array>, but is instead of type <#{@routines.class}>!"
          fail
        end

        # allowing a config for empty routines for usecase of
        # determining routines on the fly dynamically
        if @routines.empty? && !@allow_empty_routines
          Origen.log.error "Profile #{id}: routines array is empty!"
          Origen.log.warn "If you'd like to enable profile creation without routines, set the profile's @allow_empty_routines attribute to true"
          fail
        end

        unknown_routines = @routines - @defined_routines
        unless unknown_routines.empty?
          Origen.log.error "Profile #{id}: unknown routines: #{unknown_routines}"
          fail
        end

        @valid_placements ||= [:inline, :eof]
        unless @valid_placements.include? @placement
          Origen.log.error "Profile #{id}: invalid placement value, must be one of: #{@valid_placements}"
          fail
        end

        if @on_result
          @valid_on_results ||= [:on_fail, :fail, :failed, :on_pass, :pass, :passed]
          unless @valid_on_results.include?(@on_result)
            Origen.log.error "Profile #{id}: invalid on_result value, must be one of: #{@valid_on_results}"
            fail
          end
        end

        if @charz_only && @on_result
          Origen.log.error "Profile #{id}: @charz_only is set, but @on_result (#{@on_result}) requires the parent test to exist in the flow"
          fail
        end

        unless @gate_checks == false
          gate_check(@enables, :enables) if @enables
          gate_check(@flags, :flags) if @flags
        end
      end

      def gate_check(gates, gate_type)
        case gates
        when Symbol, String
          nil
        when Array
          unknown_gates = gates.reject { |gate| [String, Symbol].include? gate.class }
          if unknown_gates.empty?
            nil
          else
            Origen.log.error "Profile #{id}: Unknown #{gate_type} type(s) in #{gate_type} array."
            Origen.log.error "Arrays must contain Strings and/or Symbols, but #{unknown_gates.map(&:class).uniq} were found in #{gates}"
            fail
          end
        when Hash
          gates.each do |gate, gated_routines|
            if gate.is_a? Hash
              Origen.log.error "Profile #{id}: #{gate_type} Hash keys cannot be of type Hash, but only Symbol, String, or Array"
              fail
            end
            gate_check(gate, gate_type)
            gated_routines = [gated_routines] unless gated_routines.is_a? Array
            unknown_routines = gated_routines - @defined_routines
            unless unknown_routines.empty?
              Origen.log.error "Profile #{id}: unknown routines found in @#{gate_type}[#{gate.is_a?(Symbol) ? ':' : ''}#{gate}]: #{unknown_routines}"
              fail
            end
          end
        else
          Origen.log.error "Profile #{id}: Unknown #{gate_type} type: #{gates.class}. #{gate_type} must be of type Symbol, String, Array, or Hash"
          fail
        end
      end

      def method_missing(m, *args, &block)
        ivar = "@#{m.to_s.gsub('=', '')}"
        ivar_sym = ":#{ivar}"
        if m.to_s =~ /=$/
          define_singleton_method(m) do |val|
            instance_variable_set(ivar, val)
          end
        elsif instance_variables.include? ivar_sym
          instance_variable_get(ivar)
        else
          define_singleton_method(m) do
            instance_variable_get(ivar)
          end
        end
        send(m, *args, &block)
      end
    end
  end
end
