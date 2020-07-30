require_relative 'charz/profile'
require_relative 'charz/routine'
module OrigenTesters
  module Charz
    attr_accessor :charz_stack, :charz_routines, :charz_profiles

    def charz_stack
      @charz_stack ||= []
    end

    def add_charz_profile(id, options = {}, &block)
      @charz_profiles ||= {}
      if @charz_profiles.include?(id)
        Origen.log.error("Cannot create charz profile '#{id}', it already exists!")
        fail
      end
      @charz_profiles[id] = profile.new(id, options, &block)
    end

    def add_charz_routine(id, options = {}, &block)
      @charz_routines ||= {}
      if @charz_routines.include?(id)
        Origen.log.error("Cannot create charz routine '#{id}', it already exists!")
        fail
      end
      @charz_routines[id] = Routine.new(id, options, &block)
    end

    def charz_on(profile_id, options = {})
      if options.empty?
        @char_stack.push(@charz_profiles[profile_id])
      else
        # generate id of on the fly profile generation
        if options[:id]
          impromptu_id = options[:id]
        else
          impromptu_id = :"#{profile_id}_#{options.hash}"
        end
        # if existing profile was passed same options previously, re-use profile
        # otherwise, copy the referenced profile and update with options passed in from flow
        if @charz_profiles[impromptu_id]
          @char_stack.push(@charz_profiles[impromptu_id])
        else
          impromptu_profile = clone_and_add_charz_profile(profile_id, impromptu_id, options) 
          @charz_stack.push(impromptu_profile)
        end
      end
    end

    def charz_off
      @charz_stack.pop
    end

  end
end
# 
#   module Helpers
# 
#     # call from your Interface#add_to_flow, return before adding the method to the flow if true
#     # @example
#     #   def add_to_flow(instance, test_obj, options)
#     #     return if charz_only?(options)
#     def charz_only?(options)
#       if options[:charz]
#         if options[:charz][:charz_only]
#           options[:charz][:charz_only]
#         else
#           false
#         end
#       else
#         false
#       end
#     end
# 
#   end
