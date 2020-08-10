module OrigenTesters
  module Charz
    # A 2D search or "Shmoo" routine
    class ShmooRoutine < Routine

      # @!attribute x_start
      #   @return [Numeric] the starting search value for the x dimension's spec search 
      # @!attribute x_stop
      #   @return [Numeric] the stopping search value for the x dimension's spec search
      # @!attribute x_res
      #   @return the search resolution value for the x dimension's spec search
      # @!attribute x_spec
      #   @return [Symbol, String] the spec parameter of interest for the x dimension 
      attr_accessor :x_start, :x_stop, :x_res, :x_spec
      # @!attribute y_start
      #   @return [Numeric] the starting search value for the x dimension's spec search 
      # @!attribute y_stop
      #   @return [Numeric] the stopping search value for the x dimension's spec search
      # @!attribute y_res
      #   @return the search resolution value for the x dimension's spec search
      # @!attribute y_spec
      #   @return [Symbol, String] the spec parameter of interest for the x dimension 
      attr_accessor :y_start, :y_stop, :y_res, :y_spec

      def initialize(id, options = {}, &block)
        super
        attrs_ok?
      end

      def attrs_ok?
        return if @quality_check == false

        @required_attrs ||= [:x_start, :x_stop, :x_res, :x_spec, :y_start, :y_stop, :y_res, :y_spec]
        attrs = @required_attrs.map { |attr| instance_variable_get("@#{attr}") }
        if attrs.compact.size != @required_attrs.size
          Origen.log.error "ShmooRoutine #{@id}: unspecified attributes, each of #{@required_attrs} must have a value"
          fail
        end

        return if @attr_value_check == false

        # TODO not sure if I want this check, if so need to scope out if step count is common

        # if [@x_start, @x_stop, @x_res].all? { |attr| attr.is_a? Numeric } 
        #   unless @x_res <= (@x_start - @x_stop).abs
        #     Origen.log.error "ShmooRoutine #{@id}: Search x_resolution (#{@x_res} is larger than the search x_range (#{@x_start - @x_stop).abs})"
        #     fail
        #   end
        # end
        # if [@y_start, @y_stop, @y_res].all? { |attr| attr.is_a? Numeric } 
        #   unless @y_res <= (@y_start - @y_stop).abs
        #     Origen.log.error "ShmooRoutine #{@id}: Search y_resolution (#{@y_res} is larger than the search y_range (#{@y_start - @y_stop).abs})"
        #     fail
        #   end
        # end
        unless @x_spec != @y_spec
          Origen.log.error "ShmooRoutine #{@id}: Search x_spec is identical to y_spec"
          fail
        end
      end


    end
  end
end
