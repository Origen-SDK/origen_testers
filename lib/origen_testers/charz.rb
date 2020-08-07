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

    def add_charz_profile(id, options = {}, &block)
      if charz_profiles.include?(id)
        Origen.log.error("Cannot create charz profile '#{id}', it already exists!")
        fail
      end
      charz_profiles[id] = Profile.new(id, options.merge(available_routines: charz_routines.ids), &block)
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
      charz_stack.push([charz_obj, options])
      unless update_charz_session(*charz_stack.last)
        Origen.log.error "charz_on failed to create a valid charz session"
        fail
      end
    end

    def insert_charz_tests(options = {})
      options = {
        skip_group: false,
      }.merge(options)
      if charz_active?
        case charz_session.placement
        when :inline
          create_charz_group(options, &block)
        when :on_fail
          create_charz_group(options, &block)
        when :on_pass
          create_charz_group(options, &block)
        else
          if respond_to?(:"create_#{charz_session.placement}_tests")
            send(:"create_#{charz_session.placement}_tests", options, &block)
          elsif respond_to?(:"insert_#{charz_session.placement}_tests")
            send(:"insert_#{charz_session.placement}_tests", options, &block)
          else
            Origen.log.error "No handling specified for #{charz_session.placement} placement tests"
            fail
          end
        end
      end
    end

# def create_charz_group(test_name)
#   if current_charz_session.enables.empty?
#     group "#{test_name}_#{current_charz.profile}_charz".to_sym do
#       instantiate_charz_tests
#     end
#   elsif current_charz_session.enables.is_a?(Array)
#     if_enable current_charz_session.enables do
#       group "#{test_name}_#{current_charz.profile}_charz".to_sym do
#         instantiate_charz_tests
#       end
#     end
#   else
#     # instantiate tests without flag gates
#     group "#{test_name}_#{current_charz.profile}_charz".to_sym do
#       instantiate_charz_tests(current_charz.routines.map(&:type) - current_charz.enables.values.flatten)
#     end
#     # instantiate tests whose routines map to flags
#     current_charz_session.enables.each do |flags, routines|
#       if_enable flags do
#         group "#{test_name}_#{current_charz.profile}_charz".to_sym do
#           instantiate_charz_tests(routines)
#         end
#       end
#     end
#   end
# end
    private

    def update_charz_session(charz_obj, options = {})
      charz_session.update(charz_obj, options.merge(available_routines: charz_routines.ids))
    end

  end
end

# def create_eof_charz_tests
#   [].tap do |ary|
#     charz_sessions.select { |cs| cs.placement == :eof }.each do |cs|
#       ary << generate_charz_tests(cs)
#     end
#   end.flatten
# end
# 
# def insert_charz_tests(test_instance)
#   unless current_charz.nil?
#     if current_charz.test_instances_created.size > 0
#       case current_charz.placement
#       when :inline
#         create_charz_group(test_instance.flow_name)
#       when :on_fail
#         if_failed @last_test_called do
#           create_charz_group(test_instance.flow_name)
#         end
#       when :on_pass
#         if_passed @last_test_called do
#           create_charz_group(test_instance.flow_name)
#         end
#       end
#       current_charz.clear_queue unless current_charz.placement == :eof
#       charz_off if current_charz.close_after_completion?
#     end
#   end
# end
# 
# def create_charz_group(test_name)
#   if current_charz_session.enables.empty?
#     group "#{test_name}_#{current_charz.profile}_charz".to_sym do
#       instantiate_charz_tests
#     end
#   elsif current_charz_session.enables.is_a?(Array)
#     if_enable current_charz_session.enables do
#       group "#{test_name}_#{current_charz.profile}_charz".to_sym do
#         instantiate_charz_tests
#       end
#     end
#   else
#     # instantiate tests without flag gates
#     group "#{test_name}_#{current_charz.profile}_charz".to_sym do
#       instantiate_charz_tests(current_charz.routines.map(&:type) - current_charz.enables.values.flatten)
#     end
#     # instantiate tests whose routines map to flags
#     current_charz_session.enables.each do |flags, routines|
#       if_enable flags do
#         group "#{test_name}_#{current_charz.profile}_charz".to_sym do
#           instantiate_charz_tests(routines)
#         end
#       end
#     end
#   end
# end
# 
# def instantiate_charz_tests(enabled_routines = nil)
#   if enabled_routines.nil?
#     current_charz.test_instances_created.each do |curr_charz_instance|
#       instantiate_test curr_charz_instance, type: :charz
#     end
#   elsif !enabled_routines.empty?
#     current_charz.test_instances_created.select { |cz_inst| enabled_routines.include?(cz_inst.charz_routine_name) }.each do |curr_charz_instance|
#       instantiate_test curr_charz_instance, type: :charz
#     end
#   end
# end
# 
