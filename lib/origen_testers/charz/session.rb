module OrigenTesters
  module Charz
    # A charz session
    # contains the final combination of charz object (routines/profiles) and user options to determine how and what charz tests should be created
    # the session should be checked in your interface to determine the current status and can be queried to make charz generation decisions
    class Session < Profile
      # @!attribute defaults
      #   @return [Hash] list of values to instantiate the inherited attributes from Profile with if not altered by the session update
      attr_accessor :defaults

      def initialize(options = {})
        @id = :current_charz_session
        @active = false
        @valid = false
        if options[:defaults]
          @defaults = options[:defaults]
        else
          @defaults = {
            placement:  :inline,
            on_result:  nil,
            enables:    nil,
            flags:      nil,
            enables_and: nil,
            name:       'charz',
            charz_only: false
          }
        end
      end

      # Pauses the current session's activity while maintaining everthing else about the sessions state
      def pause
        @active = false
      end

      # Resume activity, if the session is valid
      def resume
        if @valid
          @active = true
        end
      end

      # Takes a Routine or Profile, and queries it to setup the session's attributes
      # the attributes values can be set from 3 different sources, in order of priority (first is most important):
      #   - options
      #   - charz object
      #   - defaults
      #
      # If the resulting session is invalid, @valid will turn false. Otherwise, the session becomes active
      def update(charz_obj, options)
        @valid = false
        if charz_obj.nil?
          @active = false
          @valid = false
          return @valid
        end
        @defined_routines = options.delete(:defined_routines)

        if charz_obj.and_flags
          @and_flags = charz_obj.and_flags
        else
          @and_flags = false
        end
        if charz_obj.and_enables
          @and_enables = charz_obj.and_enables
        else
          @and_enables = false
        end
        assign_by_priority(:placement, charz_obj, options)
        assign_by_priority(:on_result, charz_obj, options)
        assign_by_priority(:enables, charz_obj, options)
        assign_by_priority(:flags, charz_obj, options)
        assign_by_priority(:routines, charz_obj, options)
        assign_by_priority(:name, charz_obj, options)
        assign_by_priority(:charz_only, charz_obj, options)
        attrs_ok?
        massage_gates
        @active = true
        @valid = true
      end

      private

      # convert hash gates to set convert their routines to type array if not already
      def massage_gates
        if @enables.is_a?(Hash)
          @enables = {}.tap do |new_h|
            @enables.each { |gates, routines| new_h[gates] = [routines].flatten }
          end
        end
        if @flags.is_a?(Hash)
          @flags = {}.tap do |new_h|
            @flags.each { |gates, routines| new_h[gates] = [routines].flatten }
          end
        end
      end

      # see initialize
      def assign_by_priority(ivar, charz_obj, options)
        if options.keys.include?(ivar)
          instance_variable_set("@#{ivar}", options[ivar])
        elsif charz_obj.send(ivar)
          instance_variable_set("@#{ivar}", charz_obj.send(ivar))
        elsif @defaults.keys.include?(ivar)
          instance_variable_set("@#{ivar}", @defaults[ivar])
        else
          Origen.log.error "Charz Session: No value could be determined for #{ivar}"
          fail
        end
      end
    end
  end
end
