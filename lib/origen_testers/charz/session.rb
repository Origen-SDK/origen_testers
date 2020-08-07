module OrigenTesters
  module Charz
    class Session < Profile

      attr_accessor :defaults

      def initialize
        @id = :current_charz_session
        @active = false
        @valid_session = false
        @defaults = {
          placement: :inline,
          enables: nil,
          flags: nil,
          name: 'charz',
          charz_only: false
        }
      end

      def active?
        @active
      end

      def pause
        @active = false
      end

      def resume
        if @valid_session
          @active = true
        end
      end

      def update(charz_obj, options)
        @valid_session = false
        if charz_obj.nil?
          @active = false
          @valid_session = false
          return @valid_session
        end
        @available_routines = options.delete(:available_routines)
        assign_by_priority(:placement, charz_obj, options)
        assign_by_priority(:enables, charz_obj, options)
        assign_by_priority(:flags, charz_obj, options)
        assign_by_priority(:routines, charz_obj, options)
        assign_by_priority(:name, charz_obj, options)
        assign_by_priority(:charz_only, charz_obj, options)
        attrs_ok?
        @active = true
        @valid_session = true
      end

      private

      def assign_by_priority(ivar, charz_obj, options)
        if options[ivar]
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
