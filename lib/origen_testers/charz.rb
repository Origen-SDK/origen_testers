Dir.glob("#{File.dirname(__FILE__)}/charz/**/*.rb").sort.each do |file|
  require file
end
module OrigenTesters
  module Charz
    CharzTuple = Struct.new(:obj, :options, :defined_routines, keyword_init: true)
    # @!attribute charz_stack
    #   @return [Array] FILO queue of charz session defining data
    # @!attribute charz_routines
    #   @return [Hash] user defined charz routines
    # @!attribute charz_profiles
    #   @return [Hash] user defined charz profiles
    # @!attribute charz_session
    #   @return [Session] current charz session, based on data in the top of the charz_stack
    # @!attribute charz_instance
    #   @return [Session] current charz instance of the session. If there is not a current instance, will return the first instance of the session instance stack
    # @!attribute eof_charz_tests
    #   @return [Array] charz tests to be added at the end of the flow
    # @!attribute skip_group_eof_charz_tests
    #   @return [Boolean] whether or not to wrap eof charz tests in a group
    # @!attribute eof_charz_tests_group_name
    #   @return [String, Symbol] group name to be used to for eof charz tests
    # @!attribute default_valid_charz_placements
    #   @return [Array<Symbol>] (:inline, :eof) list of charz placements used when verifying a new profile is valid
    attr_accessor :charz_stack, :charz_routines, :charz_profiles, :charz_session, :charz_instance,
                  :eof_charz_tests, :skip_group_eof_charz_tests, :eof_charz_tests_group_name,
                  :default_valid_charz_placements

    def charz_stack
      @charz_stack ||= []
    end

    def charz_profiles
      @charz_profiles ||= {}
    end

    def charz_routines
      @charz_routines ||= {}
    end

    def charz_session
      @charz_session ||= Session.new
    end

    def default_valid_charz_placements
      @default_valid_charz_placements ||= [:inline, :eof]
    end

    # If there is a current instance present, that should always be used. However when running EOF charz,
    # the instance to be used is no longer set, so instead of referencing the session, use the one that we've
    # stored already
    def charz_instance
      unless charz_session.current_instance(stored_instance_valid: true).nil?
        set_charz_instance(charz_session.current_instance(stored_instance_valid: true))
      end
      @charz_instance
    end

    def set_charz_instance(instance)
      @charz_instance = instance
      charz_session.stored_instance = instance
    end

    def eof_charz_tests
      @eof_charz_tests ||= []
    end

    # Add a new charz routine to @charz_routines
    # A charz routine is a object that contains all the necessary info specific to a characterization test
    # Its intended to be used in combination with an existing point test (regular non charz test) to create
    # a characterization version of the point test
    #
    # To use your own Routine classes, override the create_charz_routine method in your interface
    #
    # @example create a 1d search routine that searches vdd, from 900mv to 300mv, resolution of 5mv
    #   add_charz_routine :my_routine, type: search do |rt|
    #     rt.start = 900.mv
    #     rt.stop  = 300.mv
    #     rt.res   = 5.mv
    #     rt.spec  = 'vdd'
    #   end
    #
    # @param [Symbol] id charz_routine id, will be the key value in the @charz_routines hash. Must not have been previously used
    # @param [Hash] options charz_routine options
    # @option options [Symbol] :type :search or :'1d' will create a SearchRoutine, :shmoo or :'2d' will create a ShmooRoutine, nil will create a Routine
    def add_charz_routine(id, options = {}, &block)
      if charz_routines.ids.include?(id)
        Origen.log.error("Cannot create charz routine '#{id}', it already exists!")
        fail
      end
      charz_routines[id] = create_charz_routine(id, options, &block)
    end

    # Called by add_charz_routine, split out from that method to make it easier to override this handler from a user's interface
    # This is the method to override if you want to use custom Routines specifc to your company's implementation
    #
    # @param [Symbol] id charz_routine id, will be the key value in the @charz_routines hash. Must not have been previously used
    # @param [Hash] options charz_routine options
    # @option options [Symbol] :type :search or :'1d' will create a SearchRoutine, :shmoo or :'2d' will create a ShmooRoutine, nil will create a Routine
    # @return [Routine] a charz routine object
    def create_charz_routine(id, options = {}, &block)
      case options[:type]
      when :search, :'1d'
        SearchRoutine.new(id, options, &block)
      when :shmoo, :'2d'
        ShmooRoutine.new(id, options, &block)
      else
        Routine.new(id, options, &block)
      end
    end

    # Add a new charz profile to @charz_profiles
    # A charz profile is a collection of one or more charz routines, as well as flow control and placement data for
    # the charz tests generated by those routines
    #
    # @example create a profile containing 2 routines, end of flow placement, whose tests are only ran if the parent fails
    #   add_charz_profile :my_profile do |prof|
    #     prof.routines  = [:my_routine1, :my_routine2]
    #     prof.placement = :eof
    #     prof.on_result = :on_fail
    #   end
    #
    # @param [Symbol] id charz_profile id, will be the key value in the @charz_profiles hash. Must not have been previously used
    # @param [Hash] options charz_profile options
    def add_charz_profile(id, options = {}, &block)
      if charz_profiles.ids.include?(id)
        Origen.log.error("Cannot create charz profile '#{id}', it already exists!")
        fail
      end
      charz_profiles[id] = Profile.new(id, options.merge(defined_routines: charz_routines.ids), &block)
    end

    # Queries the current charz session to see if its active, indicating point tests should be generating charz tests
    def charz_active?
      charz_session.active?
    end

    # Queries the current charz session to see if point tests should skip generation, only adding the resulting charz test
    def charz_only?
      charz_active? && charz_session.charz_only?
    end

    # Pauses the current charz session, preventing point tests from generating charz tests even if the session is valid
    def charz_pause
      charz_session.pause
    end

    # Resumes the current charz session. If the session isn't valid (ie charz_resume before setting up the session) then nothing will happen
    def charz_resume
      charz_session.resume
    end

    # Removes the current session generating data off the charz stack
    # If charz data is still on the stack afterward, the session will update to reflect the new data
    # if not, the session will become inactive
    def charz_off
      charz_stack.pop
      unless charz_session.update(charz_stack.last) || charz_stack.empty?
        Origen.log.error 'charz_on failed to create a valid charz session'
        fail
      end
      if charz_stack.empty?
        set_charz_instance(nil)
      end
    end

    # Pushes a charz object (either a profile or a routine) onto the stack, along with any optional updates to modify the current session
    # Once pushed, the charz_session will attempt to update itself with the new data, failing if the resulting session is invalid
    #
    # If a block is passed, yield the block of tests to enable charz for those tests, then disable charz with a charz_off call
    #
    # @param [Symbol] charz_id either a routine or profile id. Method fails if the id can't be found in @charz_routines or @charz_profiles
    # @param [Hash] options charz_on options
    # @option options [Symbol] :type (:profile) whether the charz_id refers to a charz profile or routine
    def charz_on(charz_id, options = {})
      charz_stack.push([get_charz_tuple(charz_id, options)])
      unless charz_session.update(charz_stack.last)
        Origen.log.error 'charz_on failed to create a valid charz session'
        fail
      end
      if block_given?
        yield
        charz_off
      end
    end

    # Pushes a charz object (either a profile or a routine) onto the current sessions instance stack, along with any optional updates to modify that instance.
    # This will result in subsequent charzable point tests in being processed against each of the current instances. In other words, this new push will not
    # take priority over the current stack head, but instead append to it.
    # Once pushed, the charz_session will attempt to update itself with the new data, failing if the resulting session is invalid
    #
    # If a block is passed, yield the block of tests to enable charz for those tests, then disable charz with a charz_off_truncate call
    #
    # @param [Symbol] charz_id either a routine or profile id. Method fails if the id can't be found in @charz_routines or @charz_profiles
    # @param [Hash] options charz_on options
    # @option options [Symbol] :type (:profile) whether the charz_id refers to a charz profile or routine
    def charz_on_append(charz_id, options = {})
      charz_tuple = get_charz_tuple(charz_id, options)

      # take the current session and append to its instance stack
      session = charz_stack.pop || []
      session.push(charz_tuple)
      charz_stack.push(session)

      unless charz_session.update(charz_stack.last)
        Origen.log.error 'charz_on failed to create a valid charz session'
        fail
      end
      if block_given?
        yield
        charz_off_truncate
      end
    end

    # Removes the current sessions last instance. If the session only had one instance, this is functionally the same as charz_off
    # If charz data is still on the stack afterward, the session will update to reflect the new data
    # if not, the session will become inactive
    def charz_off_truncate
      session = charz_stack.pop || []
      session.pop
      unless session.empty?
        charz_stack.push(session)
      end

      unless charz_session.update(charz_stack.last) || charz_stack.empty?
        Origen.log.error 'charz_on failed to create a valid charz session'
        fail
      end
      if charz_stack.empty?
        set_charz_instance(nil)
      end
    end

    # An optional helper method to automatically assign an id to tests that will be generating charz tests that depend on the result of the parent test
    # @param [Hash] options the options for a test before its created and added to the flow
    # @param [TestInstance, #name] instance <Optional> the test instance whose name is stored in .name, alternatively pass the name in the options hash under :parent_test_name
    def set_conditional_charz_id(*args)
      case args.size
      when 1
        options = args[0]
        parent_test_name = options[:parent_test_name]
      when 2
        instance = args[0]
        options = args[1]
        parent_test_name = instance.name
      else
        Origen.log.error 'Too many arguments passed to set_conditional_charz_id. Pass either (test_instance, options), or just (options)'
        fail
      end
      unless options[:id]
        if charz_active?
          if charz_session.on_result?
            md5_id = Digest::MD5.new
            md5_id << parent_test_name.to_s
            md5_id << options.to_s
            md5_id << charz_session.id.to_s
            options[:id] = "auto_charz_id_#{md5_id}".to_sym
          end
        end
      end
    end

    # Called after the relevant point test has been inserted into the flow
    # Takes the options used to build the previous point test as well as insert_charz_test specific options to then
    # drill down to the point of the flow where the charz test would go, at which point control is handed back to the user's
    # interface to handle creating and inserting the test. This will occur for each instance in the current session's instance stack
    #
    # By default, this method will handle:
    #   - the placement of the test (inline aka right after the point test, end of flow, or other)
    #   - wrapping the created charz tests in a group (skippable, group name defaults to <point test name> charz <session name>)
    #   - conditionally executing the charz tests based on if the point test passed or failed (see set_conditional_charz_id)
    #   - conditionally executing some/all charz tests based on a mix of enables and flags
    #
    # After the above is determined, the user regains control on a per-routine (if multiple routines) basis to then process generating the charz test
    def insert_charz_tests(options, &block)
      if charz_active?
        if options[:id]
          # two purposes:
          # 1) prevent all charz tests inadverntently using the same ID as their parent
          # 2) used in on_result behavior
          current_id = options.delete(:id)
          options[:last_test_id] ||= current_id
        end
        charz_session.loop_instances do
          case charz_instance.placement
          when :inline
            create_charz_group(options, &block)
          when :eof
            # collect the current instance and options into a proc, stored in eof_charz_tests to be called later
            current_instance = charz_instance.clone
            eof_charz_tests << proc do
              set_charz_instance(current_instance)
              create_charz_group(options, &block)
            end
          else
            # inline is the default behavior, and eof (end of flow) has built in support.
            if respond_to?(:"create_#{charz_instance.placement}_charz_tests")
              send(:"create_#{charz_instance.placement}_charz_tests", options, &block)
            elsif respond_to?(:"insert_#{charz_instance.placement}_charz_tests")
              send(:"insert_#{charz_instance.placement}_charz_tests", options, &block)
            else
              Origen.log.error "No handling specified for #{charz_instance.placement} placement charz tests"
              fail
            end
          end
        end
      end
    end

    # called automatically right after a top_level shutdown, generates end of flow charz tests
    # user should not have to reference this call explicitly
    def generate_eof_charz_tests
      unless eof_charz_tests.empty?
        if skip_group_eof_charz_tests
          eof_charz_tests.map(&:call)
        else
          group_name = eof_charz_tests_group_name || 'End of Flow Charz Tests'
          group group_name do
            eof_charz_tests.map(&:call)
          end
        end
      end
    end

    private

    # helper method for charz_on and charz_on_append
    def get_charz_tuple(charz_id, options)
      options[:type] ||= :profile
      case options[:type]
      when :profile
        charz_obj = charz_profiles[charz_id]
      when :routine
        if charz_id.is_a?(Array)
          charz_obj = charz_routines[charz_id.first]
          options[:routines] = charz_id
        else
          charz_obj = charz_routines[charz_id]
          options[:routines] = [charz_id]
        end
      else
        Origen.log.error "Unknown charz object type #{options[:type]}, valid types: :profile, :routine"
        fail
      end
      if charz_obj.nil?
        Origen.log.error "No #{options[:type]} found for charz_id: #{charz_id}"
        fail
      end
      CharzTuple.new(obj: charz_obj, options: options, defined_routines: charz_routines.ids)
    end

    # called by insert_charz_tests
    #
    # if insert_charz_tests was called with the skip group option, then skip to processing the sessions on_result functionality
    # otherwise, on_result processing occurs within the created group
    #
    # group name defaults to <point test name> charz <session name>, but can be set by the user by passing :group_name in the options
    def create_charz_group(options, &block)
      if options[:skip_group]
        process_on_result(options, &block)
      else
        group_name = options[:group_name] || "#{options[:parent_test_name]} charz #{charz_instance.name}"
        group group_name.to_sym do
          process_on_result(options, &block)
        end
      end
    end

    # called by create_charz_group
    #
    # Handles the case where the session indicates these charz tests' execution depend on the point test's result
    # Requires that the id of the point test has been passed to use this functionality. Otherwise, make sure that
    # charz_session.on_result == nil
    #
    # on_fail and on_pass results are built-in, but if the user has a different check to make, it can be handled
    # by defining the method process_<custom result>_charz_tests
    #
    # @see set_conditional_charz_id
    def process_on_result(options, &block)
      if charz_instance.on_result
        case charz_instance.on_result
        when :on_fail, :fail, :failed
          last_test_id = options[:last_test_id] || @last_test_id
          if_failed last_test_id do
            process_gates(options, &block)
          end
        when :on_pass, :pass, :passed
          last_test_id = options[:last_test_id] || @last_test_id
          if_passed last_test_id do
            process_gates(options, &block)
          end
        else
          if respond_to?(:"process_#{charz_instance.placement}_charz_tests")
            send(:"process_#{charz_instance.on_result}_charz_tests", options, &block)
          else
            Origen.log.error "No handling specified for result #{charz_instance.on_result} charz tests"
            fail
          end
        end
      else
        process_gates(options, &block)
      end
    end

    # called by process_on_result
    #
    # Handles the case where charz_session.enables or charz_session.flags have been set
    # referring to enables and flags both as gates, gates can wrap all routines in a session if they're in the form of an
    # array, symbol, or a string (think of the normal use case of if_enable or if_flag)
    #
    # If the gate is a Hash, then that means different routines are getting different gate wrappers.
    # Also if a routine is not indicated in the values of the gate, then that means that routine should not be gated at all
    #
    # This is the final method of handling the insert_charz_test usecases, where the block thats been passed around is finally called
    # the user's provided block is passed the current routine (one at a time) to then take its info to generate a charz test

    # Pass an "and_if_true" variable for enables and flags? And use that to to decide what to do? Then we don't need 4.
    # But the hash has to be structured a different way for the enable_and (routine is key, enables is value.)
    def process_gates(options, &block)
      if options[:skip_gates] || !(charz_instance.enables || charz_instance.flags)
        charz_instance.routines.each do |routine|
          block.call(options.merge(current_routine: routine))
        end
      else
        if charz_instance.and_enables
          if charz_instance.flags
            # Wrap all tests in flag, wrap some tests in anded enables.
            ungated_routines = charz_instance.routines - charz_instance.enables.keys
            ungated_routines.each do |routine|
              if_flag charz_instance.flags do
                block.call(options.merge(current_routine: routine))
              end
            end
            gated_routines = charz_instance.routines - ungated_routines
            # Build the proc which contains the nested if statements for each routine so they are anded.
            gated_routines.each do |routine|
              my_proc = -> do
                if_flag charz_instance.flags do
                  block.call(options.merge(current_routine: routine))
                end
              end
              charz_instance.enables[routine].inject(my_proc) do |my_block, enable|
                lambda do
                  if_enable :"#{enable}" do
                    my_block.call
                  end
                end
              end.call
            end
          else
            ungated_routines = charz_instance.routines - charz_instance.enables.keys
            ungated_routines.each do |routine|
              block.call(options.merge(current_routine: routine))
            end
            # Build the proc which contains the nested if statements for each routine so they are anded.
            gated_routines = charz_instance.routines - ungated_routines
            gated_routines.each do |routine|
              my_proc = -> { block.call(options.merge(current_routine: routine)) }
              charz_instance.enables[routine].inject(my_proc) do |my_block, enable|
                lambda do
                  if_enable :"#{enable}" do
                    my_block.call
                  end
                end
              end.call
            end
          end
        elsif charz_instance.and_flags
          if charz_instance.enables
            # Wrap all tests in enable, some tests in anded flags.
            ungated_routines = charz_instance.routines - charz_instance.flags.keys
            ungated_routines.each do |routine|
              if_enable charz_instance.enables do
                block.call(options.merge(current_routine: routine))
              end
            end
            # Build the proc which contains the nested if statemements for each routine so they are anded.
            gated_routines = charz_instance.routines - ungated_routines
            gated_routines.each do |routine|
              my_proc = -> do
                if_enable charz_instance.enables do
                  block.call(options.merge(current_routine: routine))
                end
              end
              charz_instance.flags[routine].inject(my_proc) do |my_block, flag|
                lambda do
                  if_flag :"#{flag}" do
                    my_block.call
                  end
                end
              end.call
            end
          else
            ungated_routines = charz_instance.routines - charz_instance.flags.keys
            ungated_routines.each do |routine|
              block.call(options.merge(current_routine: routine))
            end
            # Build the proc which contains the nested if statemements for each routine so they are anded.
            gated_routines = charz_instance.routines - ungated_routines
            gated_routines.each do |routine|
              my_proc = -> { block.call(options.merge(current_routine: routine)) }
              charz_instance.flags[routine].inject(my_proc) do |my_block, flag|
                lambda do
                  if_flag :"#{flag}" do
                    my_block.call
                  end
                end
              end.call
            end
          end
        elsif charz_instance.enables && charz_instance.flags
          if charz_instance.enables.is_a?(Hash) && !charz_instance.flags.is_a?(Hash)
            # wrap all tests in flags, wrap specific tests in enables
            if_flag charz_instance.flags do
              insert_hash_gates(options, charz_instance.enables, :if_enable, &block)
            end
          elsif !charz_instance.enables.is_a?(Hash) && charz_instance.flags.is_a?(Hash)
            # wrap all tests in enables, wrap specific tests in flags
            if_enable charz_instance.enables do
              insert_hash_gates(options, charz_instance.flags, :if_flag, &block)
            end
          elsif charz_instance.enables.is_a?(Hash) && charz_instance.flags.is_a?(Hash)
            # first insert the tests that are not tied to an enable or flag gate
            ungated_routines = charz_instance.routines - (charz_instance.enables.values.flatten | charz_instance.flags.values.flatten)
            ungated_routines.each do |routine|
              block.call(options.merge(current_routine: routine))
            end
            # wrap tests in an enable gate, flag gate, or both
            gated_routines = charz_instance.routines - ungated_routines
            gated_routines.each do |routine|
              enable = charz_instance.enables.find { |gates, routines| routines.include?(routine) }&.first
              flag = charz_instance.flags.find { |gates, routines| routines.include?(routine) }&.first
              if enable && flag
                if_enable enable do
                  if_flag flag do
                    # wrap test in both enable and flag gate
                    block.call(options.merge(current_routine: routine))
                  end
                end
              elsif enable
                if_enable enable do
                  # enable only
                  block.call(options.merge(current_routine: routine))
                end
              elsif flag
                if_flag flag do
                  # flag only
                  block.call(options.merge(current_routine: routine))
                end
              end
            end
          else
            # both enable and flag is set, and both apply to all routines in session
            if_enable charz_instance.enables do
              if_flag charz_instance.flags do
                charz_instance.routines.each do |routine|
                  block.call(options.merge(current_routine: routine))
                end
              end
            end
          end
        else
          # only enables or flags is set, not both
          if charz_instance.enables
            gates = charz_instance.enables
            gate_method = :if_enable
          elsif charz_instance.flags
            gates = charz_instance.flags
            gate_method = :if_flag
          end
          if gates.is_a?(Hash)
            # wrap some tests in specific gates
            insert_hash_gates(options, gates, gate_method, &block)
          else
            # wrap all tests in the indicated gates
            send(gate_method, gates) do
              charz_instance.routines.each do |routine|
                block.call(options.merge(current_routine: routine))
              end
            end
          end
        end
      end
    end

    # helper method for the process gates method above
    # handles wrapping routines in specific gates, and passing ungated routines back to the user
    def insert_hash_gates(options, gate_hash, gate_method, &block)
      ungated_routines = charz_instance.routines - gate_hash.values.flatten
      ungated_routines.each do |routine|
        block.call(options.merge(current_routine: routine))
      end
      gate_hash.each do |gate, gated_routines|
        send(gate_method, gate) do
          gated_routines.each do |routine|
            block.call(options.merge(current_routine: routine))
          end
        end
      end
    end
  end
end
