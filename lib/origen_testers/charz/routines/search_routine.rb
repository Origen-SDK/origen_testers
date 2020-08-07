module OrigenTesters
  module Charz
    class SearchRoutine < Routine

      attr_accessor :start, :stop, :res, :spec

      def initialize(id, options = {}, &block)
        super
        attrs_ok?
      end
      
      def attrs_ok?
        return if @quality_check == false

        @required_attrs ||= [:start, :stop, :res, :spec]
        attrs = @required_attrs.map { |attr| instance_variable_get("@#{attr}") }
        if attrs.compact.size != @required_attrs.size
          Origen.log.error "ShmooRoutine #{@id}: unspecified attributes, each of #{@required_attrs} must have a value"
          fail
        end

        return if @attr_value_check == false
        if [@start, @stop, @res].all? { |attr| attr.is_a? Numeric } 
          unless @res <= (@start - @stop).abs
            Origen.log.error "ShmooRoutine #{@id}: Search resolution (#{@res}) is larger than the search range: #{(@start - @stop).abs}"
            fail
          end
        end
      end

    end
  end
end
