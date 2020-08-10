Dir.glob("#{File.dirname(__FILE__)}/charz/**/*.rb").sort.each do |file|
  require file
end
module OrigenTesters
  module Charz
    attr_accessor :charz_stack, :charz_routines, :charz_profiles, :charz_session, :eof_tests

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

    def eof_tests
      @eof_tests ||= []
    end

    def add_charz_profile(id, options = {}, &block)
      if charz_profiles.include?(id)
        Origen.log.error("Cannot create charz profile '#{id}', it already exists!")
        fail
      end
      charz_profiles[id] = Profile.new(id, options.merge(defined_routines: charz_routines.ids), &block)
    end

    def add_charz_routine(id, options = {}, &block)
      if charz_routines.include?(id)
        Origen.log.error("Cannot create charz routine '#{id}', it already exists!")
        fail
      end
      case options[:type]
      when :search, :'1d'
        charz_routines[id] = SearchRoutine.new(id, options, &block)
      when :shmoo, :'2d'
        charz_routines[id] = ShmooRoutine.new(id, options, &block)
      else
        charz_routines[id] = Routine.new(id, options, &block)
      end
    end

    def charz_active?
      charz_session.active?
    end

    def charz_only?
      charz_active? && charz_session.charz_only
    end

    def charz_pause
      charz_session.pause
    end

    def charz_resume
      charz_session.resume
    end

    def charz_off
      charz_stack.pop
      if charz_stack.empty?
        update_charz_session(nil)
      else
        update_charz_session(*charz_stack.last)
      end
    end

    def charz_on(charz_id, options = {})
      options = {
        type: :profile
      }.merge(options)
      case options[:type]
      when :profile
        charz_obj = charz_profiles[charz_id]
      when :routine
        charz_obj = charz_routines[charz_id]
      else
        Origen.log.error "Unknown charz object type #{options[:type]}, valid types: :profile, :routine"
      end
      if charz_obj.nil?
        Origen.log.error "No #{options[:type]} found for charz_id: #{charz_id}"
        fail
      end
      charz_stack.push([charz_obj, options])
      unless update_charz_session(*charz_stack.last)
        Origen.log.error "charz_on failed to create a valid charz session"
        fail
      end
    end

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
        Origen.log.error "Too many arguments passed to set_conditional_charz_id. Pass either (test_instance, options), or just (options)"
        fail
      end
      unless options[:id]
        if charz_active?
          if charz_session.on_result
            options[:id] = "#{parent_test_name}_charz_#{charz_session.name}".to_sym
          end
        end
      end
    end

    def insert_charz_tests(options = {}, &block)
      if charz_active?
        case charz_session.placement
        when :inline
          create_charz_group(options, &block)
        when :eof
          current_session = charz_session
          eof_tests << proc do
            # nature of proc will remember current_session is this one
            @charz_session = current_session 
            create_charz_group(options, &block)
          end
        else
          if respond_to?(:"create_#{charz_session.placement}_charz_tests")
            send(:"create_#{charz_session.placement}_charz_tests", options, &block)
          elsif respond_to?(:"insert_#{charz_session.placement}_charz_tests")
            send(:"insert_#{charz_session.placement}_charz_tests", options, &block)
          else
            Origen.log.error "No handling specified for #{charz_session.placement} placement charz tests"
            fail
          end
        end
      end
    end

    def generate_eof_charz_tests(options = {})
      if options[:skip_group]
        eof_tests.map(&:call)
      else
        group_name = options[:group_name] || 'End of Flow Charz Tests'
        group group_name do
          eof_tests.map(&:call)
        end
      end
    end

    private

    def update_charz_session(charz_obj, options = {})
      charz_session.update(charz_obj, options.merge(defined_routines: charz_routines.ids))
    end

    def create_charz_group(options, &block)
      if options[:skip_group]
        process_on_result(options, &block)
      else
        group_name = options[:group_name] || "#{options[:parent_test_name]}_#{charz_session.name}"
        group group_name.to_sym do
          process_on_result(options, &block)
        end
      end
    end

    def process_on_result(options, &block)
      if charz_session.on_result
        case charz_session.on_result
        when :on_fail, :fail, :failed
          if_failed (options[:last_test_id] || @last_test_id) do
            process_gates(options, &block)
          end
        when :on_pass, :pass, :passed
          if_passed (options[:last_test_id] || @last_test_id) do
            process_gates(options, &block)
          end
        else
          if respond_to?(:"process_#{charz_session.placement}_charz_tests")
            send(:"process_#{charz_session.on_result}_charz_tests", options, &block)
          else
            Origen.log.error "No handling specified for result #{charz_session.on_result} charz tests"
            fail
          end
        end
      else
        process_gates(options, &block)
      end
    end

    def process_gates(options, &block)
      if options[:skip_gates] or !(charz_session.enables or charz_session.flags)
        charz_session.routines.each do |routine|
          block.call(options.merge(current_routine: routine))
        end
      else
        if charz_session.enables and charz_session.flags
          if charz_session.enables.is_a?(Hash) and !charz_session.flags.is_a?(Hash)
            if_flag charz_session.flags do
              insert_hash_gates(options, charz_session.enables, :if_enable, &block)
            end
          elsif !charz_session.enables.is_a?(Hash) and charz_session.flags.is_a?(Hash)
            if_enable charz_session.enables do
              insert_hash_gates(options, charz_session.flags, :if_flag, &block)
            end
          elsif charz_session.enables.is_a?(Hash) and charz_session.flags.is_a?(Hash)
            ungated_routines = charz_session.routines - (charz_session.enables.values.flatten | charz_session.flags.values.flatten)
            ungated_routines.each do |routine|
              block.call(options.merge(current_routine: routine))
            end
            gated_routines = charz_session.routines - ungated_routines
            gated_routines.each do |routine|
              enable = charz_session.enables.find { |gates, routines| routines.include?(routine) }&.first
              flag = charz_session.flags.find { |gates, routines| routines.include?(routine) }&.first
              if enable and flag
                if_enable enable do
                  if_flag flag do
                    block.call(options.merge(current_routine: routine))
                  end
                end
              elsif enable
                if_enable enable do
                  block.call(options.merge(current_routine: routine))
                end
              elsif flag
                if_flag flag do
                  block.call(options.merge(current_routine: routine))
                end
              end
            end
          else
            if_enable charz_session.enables do
              if_flag charz_session.flags do
                charz_session.routines.each do |routine|
                  block.call(options.merge(current_routine: routine))
                end
              end
            end
          end
        else
          if charz_session.enables
            gates = charz_session.enables
            gate_method = :if_enable
          elsif charz_session.flags
            gates = charz_session.flags
            gate_method = :if_flag
          end
          if gates.is_a?(Hash)
            insert_hash_gates(options, gates, gate_method, &block)
          else
            send(gate_method, gates) do
              charz_session.routines.each do |routine|
                block.call(options.merge(current_routine: routine))
              end
            end
          end
        end
      end
    end

    def insert_hash_gates(options, gate_hash, gate_method, &block)
      ungated_routines = charz_session.routines - gate_hash.values.flatten
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

