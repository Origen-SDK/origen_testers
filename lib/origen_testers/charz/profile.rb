module OrigenTesters
  module Charz
    class Profile

      attr_accessor :id, :name, :placement, :enables, :flags, :routines, :charz_only

      def initialize(id, options, &block)
        @id = id
        @id = @id.symbolize unless id.is_a? Symbol
        options.each { |k, v| instance_variable_set("@#{k}", v) }
        (block.arity < 1 ? (instance_eval(&block)) : block.call(self)) if block_given?
        @name ||= id
        @placement ||= :inline
        @available_routines = options.delete(:available_routines)
        attrs_ok?
      end

      def attrs_ok?
        return if @quality_check == false

        unknown_routines = @routines - @available_routines
        unless unknown_routines.empty?
          Origen.log.error "Profile #{id}: unknown routines: #{unknown_routines}"
          fail
        end

        @valid_placements ||= [:inline, :eof, :on_fail, :on_pass]
        unless @valid_placements.include? @placement
          Origen.log.error "Profile #{id}: invalid placement value, must be one of: #{@valid_placements}"
          fail
        end

        if @charz_only and [:on_fail, :on_pass].include?(@placement)
          Origen.log.error "Profile #{id}: @charz_only is set, but @placement (#{@placement}) requires the parent test to exist in the flow"
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
          return
        when Array
          unknown_gates = gates.reject { |gate| [String, Symbol].include? gate.class }
          if unknown_gates.empty?
            return
          else
            Origen.log.error "Profile #{id}: Unknown #{gate_type} type(s) in #{gate_type} array."
            Origen.log.error "Arrays must contain Strings and/or Symbols, but #{unknown_gates.map {|gate| gate.class }.uniq } were found in #{gates}"
          end
        when Hash
          gates.each do |gate, gated_routines|
            if gate.is_a? Hash
              Origen.log.error "Profile #{id}: #{gate_type} Hash keys cannot be of type Hash, but only Symbol, String, or Array"
              fail
            end
            gate_check(gate, gate_type)
            gated_routines = [gated_routines] unless gated_routines.is_a? Array
            unknown_routines = gated_routines - @available_routines
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
