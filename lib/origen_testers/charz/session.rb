module OrigenTesters
  module Charz
    # A charz session
    # contains a collection of the final combinations of charz object (routines/profiles) and user options to determine how and what charz tests should be created
    # the session should be checked in your interface to determine the current status and can be queried to make charz generation decisions
    class Session
      # @!attribute id
      #   @return [Symbol] current session ID. Will be a concatenation of the instances' ids
      # @!attribute instances
      #   @return [Array] list of active instances (which are essentially Profiles)
      # @!attribute current_instance
      #   @return [Profile] Set when looping over instances via #loop_instances. The interface can query the charz_instance for more detailed info
      # @!attribute valid
      #   @return [Boolean] whether or not the current session setup is valid, if not then charz wont be created
      # @!attribute defaults
      #   @return [Hash] list of values to instantiate the inherited attributes from Profile with if not altered by the session update
      # @!attribute stored_instance
      #   @return [Profile] This is to store the instance that the interface is storing. Its to support a legacy usecase of querying the session for instance level info during EOF
      attr_accessor :id, :instances, :current_instance, :valid, :defaults, :stored_instance

      def initialize(options = {})
        @id = :empty_session
        @instances = []
        @current_instance = nil
        @stored_instance = nil
        @active = false
        @valid = false
        @defaults = {
          placement:         :inline,
          routines:          [],
          on_result:         nil,
          enables:           nil,
          flags:             nil,
          enables_and:       false,
          and_enables:       false,
          flags_and:         false,
          and_flags:         false,
          name:              'charz',
          charz_only:        false,
          force_keep_parent: false
        }.merge((options[:defaults] || {}))
      end

      def on_result?
        instances.any? { |charz_instance| !charz_instance.on_result.nil? }
      end

      def charz_only?
        any_only = instances.any?(&:charz_only)
        any_force = instances.any?(&:force_keep_parent)
        !any_force && any_only && !on_result?
      end

      def charz_only
        Origen.log.deprecate '#charz_only has been deprecated in favor of #charz_only? It is no longer an attribute, instead a runtime calculation.'
        charz_only?
      end

      # Pauses the current session's activity while maintaining everthing else about the sessions state
      def pause
        @active = false
      end

      def active?
        !!@active
      end
      alias_method :active, :active?

      # Resume activity, if the session is valid
      def resume
        if @valid
          @active = true
        end
      end

      def current_instance(options = {})
        instance = @current_instance || instances.first
        if instance.nil? && @stored_instance
          unless options[:stored_instance_valid]
            Origen.log.deprecate '@current_instance had to source @stored_instance. This likely means charz_session.<some_attr> is being queried when the newer charz_instance.<some_attr> should be instead'
          end
          instance = @stored_instance
        end
        instance
      end

      def loop_instances
        instances.each do |charz_instance|
          @current_instance = charz_instance
          yield
          @current_instance = nil
        end
      end

      # Takes a CharzTuple and queries it to setup an instance's attributes
      # the attributes values can be set from 3 different sources, in order of priority (first is most important):
      #   - options
      #   - charz object (Profile or Routine)
      #   - defaults
      #
      # If the resulting session is invalid, @valid will turn false. Otherwise, the session becomes active
      def update(charz_tuples)
        @instances = []
        @valid = false
        if charz_tuples.nil? || charz_tuples.empty?
          @active = false
          @valid = false
          @current_instance = nil
          return @valid
        end
        @defined_routines = charz_tuples.map(&:defined_routines).flatten.uniq.compact

        charz_tuples.each do |charz_tuple|
          profile_options = assign_by_priority(charz_tuple)
          @instances << Profile.new(charz_tuple.obj.id, profile_options.merge(defined_routines: @defined_routines))
        end
        @id = instances.map(&:id).join('_').to_sym
        @active = true
        @valid = true
      end

      private

      def assign_by_priority(charz_tuple)
        options = charz_tuple.options
        charz_obj = charz_tuple.obj
        instance_options = {}
        get_instance_setting_keys(charz_obj).each do |ivar|
          if options.keys.include?(ivar)
            instance_options[ivar] = options[ivar]
          elsif charz_obj.send(ivar)
            instance_options[ivar] = charz_obj.send(ivar)
          elsif @defaults.keys.include?(ivar)
            instance_options[ivar] = @defaults[ivar]
          else
            Origen.log.error "Charz Session: No value could be determined for #{ivar}"
            fail
          end
        end
        instance_options
      end

      def get_instance_setting_keys(charz_obj)
        keys = charz_obj.instance_variables | @defaults.keys
        keys.map! { |k| k.to_s.sub('@', '').to_sym }
        keys -= [:id]
        keys
      end

      def method_missing(method, *args, &block)
        deprecated_methods = [
          :name,
          :placement,
          :on_result,
          :enables,
          :flags,
          :routines,
          :and_enables,
          :enables_and,
          :and_flags,
          :flags_and,
          :charz_only,
          :force_keep_parent
        ]
        if deprecated_methods.include?(method.to_sym) || deprecated_methods.include?(method.to_s[0..-2].to_sym)
          Origen.log.deprecate "charz_session.#{method} has been deprecated. Please query charz_instance.#{method} instead."
          if current_instance.nil? && !valid
            Origen.log.error "blocked call of 'charz_session.#{method}'!"
            Origen.log.warn 'The charz instance attributes are no longer accessible when the session is invalid!'
          else
            current_instance.send(method, *args, &block)
          end
        else
          super
        end
      end
    end
  end
end
