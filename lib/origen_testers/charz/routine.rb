module OrigenTesters
  module Charz
    # A Generic charz routine
    # Used to store characterization test specific meta data, values of which are used by the user to determine test parameter values
    class Routine

      # @!attribute id
      #   @return [Symbol] charz routine symbol, used as a key in OrigenTesters::Charz#charz_routines
      # @!attribute name
      #   @return [Symbol] the value used (if the user decides) to generate the name of the created charz test. defaults to the value of @id
      attr_accessor :id, :name

      def initialize(id, options = {}, &block)
        @id = id
        @id = @id.symbolize unless id.is_a? Symbol
        options.each { |k, v| instance_variable_set("@#{k}", v) }
        (block.arity < 1 ? (instance_eval(&block)) : block.call(self)) if block_given?
        @name ||= @id
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
