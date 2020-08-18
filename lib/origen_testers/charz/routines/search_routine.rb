module OrigenTesters
  module Charz
    # a 1D search routine
    class SearchRoutine < Routine
      # @!attribute start
      #   @return [Numeric] search start value
      # @!attribute stop
      #   @return [Numeric] search stop value
      # @!attribute res
      #   @return [Numeric] search resolution
      # @!attribute spec
      #   @return [Numeric] spec parameter to be searched
      attr_accessor :start, :stop, :res, :spec

      # Runs the same initialization as Routine
      # performs some rudimentary quality checks, which can be disabled by setting @quality_check = false
      def initialize(id, options = {}, &block)
        super
        attrs_ok?
      end

      def attrs_ok?
        return if @quality_check == false

        @required_attrs ||= [:start, :stop, :res, :spec]
        attrs = @required_attrs.map { |attr| instance_variable_get("@#{attr}") }
        if attrs.compact.size != @required_attrs.size
          Origen.log.error "SearchRoutine #{@id}: unspecified attributes, each of #{@required_attrs} must have a value"
          fail
        end

        return if @attr_value_check == false
        if [@start, @stop, @res].all? { |attr| attr.is_a? Numeric }
          unless @res <= (@start - @stop).abs
            Origen.log.error "SearchRoutine #{@id}: Search resolution (#{@res}) is larger than the search range: #{(@start - @stop).abs}"
            fail
          end
        end
      end
    end
  end
end
