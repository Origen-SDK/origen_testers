module OrigenTesters
  # This module implements the basic set of methods that a tester must have
  # in order for Origen to talk to it.
  #
  # They can be overridden by tester specific classes and who may go on to add
  # additional methods of their own.
  #
  # Essentially this API means that any class that includes Origen::Tester will
  # function as a tester, although it might not do very much!
  module API
    attr_accessor :includes
    attr_accessor :comment_level
    attr_accessor :generating
    # Get/Set the overlay style
    #
    # This method changes the way overlay is handled.
    # The default value and possible settings is dependent on the individual tester.
    #
    # @example
    #   tester.overlay_style = :label
    attr_accessor :overlay_style
    # Get/Set the capture style
    #
    # This method changes the way tester.store() implements the store
    # The default value and possible settings is dependent on the individual tester.
    #
    # @example
    #   tester.capture_style = :hram
    attr_accessor :capture_style

    def name
      @name || self.class
    end

    def generate?
      true
    end

    def generating_pattern?
      @generating == :pattern
    end

    def generating_program?
      @generating == :program
    end

    def pat_extension
      @pat_extension || 'txt'
    end
    alias_method :pattern_extension, :pat_extension

    def comment_char
      @comment_char || '//'
    end

    def program_comment_char
      @program_comment_char || comment_char
    end

    def pattern_header(*args)
    end

    def pattern_footer(*args)
    end

    def step_comment_prefix
      @step_comment_prefix || '##'
    end

    def is_vector_based?
      return @vector_based if defined?(@vector_based)
      true
    end

    def is_command_based?
      !is_vector_based?
    end

    def j750?
      is_a?(OrigenTesters::IGXLBasedTester::J750)
    end

    def j750_hpt?
      is_a?(OrigenTesters::IGXLBasedTester::J750_HPT)
    end

    def v93k?
      is_a?(OrigenTesters::SmartestBasedTester::V93K)
    end

    def ultraflex?
      is_a?(OrigenTesters::IGXLBasedTester::UltraFLEX)
    end
    alias_method :uflex?, :ultraflex?

    def igxl?
      j750? || j750_hpt? || ultraflex?
    end

    def stil?
      is_a?(OrigenTesters::StilBasedTester::Base)
    end

    def d10?
      is_a?(OrigenTesters::StilBasedTester::D10)
    end

    def link?
      !!(self.class.to_s =~ /^OrigenLink::/)
    end

    def pxie6570?
      is_a?(OrigenTesters::LabVIEWBasedTester::Pxie6570)
    end

    def doc?
      false
    end

    def smt7?
      v93k? && smt_version.to_s[0] == '7'
    end

    def smt8?
      v93k? && smt_version.to_s[0] == '8'
    end

    def annotate(msg, options = {})
    end

    def diff_friendly_output=(value)
      @diff_friendly_output = value
    end

    def diff_friendly_output?
      !!@diff_friendly_output
    end
    alias_method :diff_friendly_output, :diff_friendly_output?

    # Ignore fails on the given pins for the duration of the given block, this
    # has the effect of temporarily setting the states of the given pins to
    # don't care.
    def ignore_fails(*pins)
      pins.each(&:suspend)
      yield
      pins.each(&:resume)
    end

    # Output a comment in the pattern, normally you would not call this directly
    # and instead use these shorthand methods:
    #   cc "Some comment"
    #   ss "A single line step comment"
    #   step_comment do
    #       cc "A multi line"
    #       cc "step comment"
    #   end
    def c1(msg, options = {})
      PatSeq.add_thread(msg) unless options[:no_thread_id]
      prefix = comment_char + ' '
      prefix += step_comment_prefix + ' ' if @step_comment_on
      if Origen.tester.generating == :program
        cc_coms = OrigenTesters::Flow.cc_comments
        # cc call must be on line directly before test method
        line_number = caller_locations(2, 1)[0].lineno + 1
        unless cc_coms[line_number]
          cc_coms[line_number] = []
        end
        cc_coms[line_number] << msg
      else
        push_comment(prefix + msg.to_s)
      end
    end

    def c2(msg, options = {})
      c1(msg, options)
    end

    def pattern_section(msg)
      if generating_program?
        yield
      else
        step_comment(msg)
        yield
      end
    end

    def ss(msg = nil)
      div = step_comment_prefix.length
      div = 1 if div == 0
      c1(step_comment_prefix * (70 / div), no_thread_id: true)
      @step_comment_on = true
      if block_given?
        yield
      else
        c1(msg)
      end
      @step_comment_on = false
      if $_testers_enable_vector_comments
        timestamp = " #{execution_time_in_ns}ns #{step_comment_prefix}"
        str = step_comment_prefix * (70 / div)
        c1(str.sub(/#{step_comment_prefix}{#{timestamp.length - 1}}$/, timestamp), no_thread_id: true)
      else
        c1(step_comment_prefix * (70 / div), no_thread_id: true)
      end
    end

    def snip(number, options = {})
      yield
    end

    # Allows a section to be run without actually generating any vectors. This can be useful
    # to ensure the pin states end up as they otherwise would have if the section had been run.
    # Classic example of this is a subroutine pattern, wrap this around a call to the startup
    # routine to ensure the pin states are as they would have been immediately after the startup.
    # ==== Example
    #   # Setup state as if I had run startup without actually doing so
    #   $tester.inhibit_vectors_and_comments do
    #       $soc.startup
    #       $top.startup
    #   end
    def inhibit_vectors_and_comments
      inhibit_vectors = @inhibit_vectors
      inhibit_comments = @inhibit_comments
      @inhibit_vectors = true
      @inhibit_comments = true
      yield
      @inhibit_vectors = inhibit_vectors      # Restore to their initial state
      @inhibit_comments = inhibit_comments
    end

    # Generate a vector.
    # Calling this method will generate a vector in the output pattern based on the
    # current pin states and timeset.
    def cycle(options = {})
      options = {
        microcode: '',
        timeset:   current_timeset,
        pin_vals:  current_pin_vals,
        repeat:    nil
      }.merge(options)

      if PatSeq.thread
        PatSeq.thread.cycle(options)
      else
        if any_clocks_running?
          update_running_clocks
          if options[:repeat]
            slice_repeats(options).each do |slice|
              options[:repeat] = slice[0]
              delay(options.delete(:repeat), options) do |options|
                push_vector(options)
              end
              slice[1].each { |clock_pin_name| clocks_running[clock_pin_name].toggle_clock }
              options[:pin_vals] = current_pin_vals
            end
            pins_need_toggling.each { |clock_pin_name| clocks_running[clock_pin_name].toggle_clock }
          else
            push_vector(options)
            pins_need_toggling.each { |clock_pin_name| clocks_running[clock_pin_name].toggle_clock }
          end
        else
          if options[:repeat]
            delay(options.delete(:repeat), options) do |options|
              push_vector(options)
            end
          else
            push_vector(options)
          end
        end
      end
    end

    def import_test_time(file, options = {})
      puts "Sorry but an importer doesn't exist for: #{Origen.tester.class}"
    end

    def any_clocks_running?
      @clocks_running.nil? ? false : @clocks_running.count > 0
    end

    def clocks_running
      @clocks_running
    end
    alias_method :running_clocks, :clocks_running

    def push_running_clock(pin)
      @clocks_running.nil? ? @clocks_running = { pin.name.to_s => pin } : @clocks_running[pin.name.to_s] = pin
    end

    def pop_running_clock(pin)
      fail "ERROR: No clocks running, doesn't make sense to pop one" unless any_clocks_running?
      @clocks_running.delete(pin.name.to_s)
    end

    def slice_repeats(options = {})
      slices = {}
      repeat_ary = []
      clocks_running.each do |name, clock_pin|
        if clock_pin.next_edge < (cycle_count + options[:repeat])
          if clock_pin.respond_to?(:duty_cycles)
            d0, d1 = clock_pin.duty_cycles
          else
            # keep legacy support for older pin_clock styling, supports only 50% duty-cycle
            d0 = clock_pin.half_period
            d1 = clock_pin.half_period
          end
          pin_slices = (clock_pin.next_edge..(cycle_count + options[:repeat])).step(d0 + d1).to_a
          pin_slices += ((clock_pin.next_edge + d0)..(cycle_count + options[:repeat])).step(d0 + d1).to_a
          pin_slices.sort!
          pin_slices.insert(0, cycle_count)
        else
          pin_slices = [cycle_count]
        end
        pin_slices.each do |cycle|
          slices[cycle].nil? ? slices[cycle] = name : slices[cycle] = "#{slices[cycle]},#{name}"
        end
        slices[cycle_count + options[:repeat]] = '' if pin_slices[-1] != cycle_count + options[:repeat]
      end
      slices.keys.sort.each do |edge_cycles|
        # puts "Toggle #{slices[edge_cycles]} on #{edge_cycles}"
        repeat_ary.push([edge_cycles, slices[edge_cycles].split(',')])
      end

      (repeat_ary.count - 1).downto(1).each { |i| repeat_ary[i][0] = repeat_ary[i][0] - repeat_ary[i - 1][0] }
      repeat_ary[1..-1]
    end

    def pins_need_toggling
      toggle_ary = []
      clocks_running.each do |name, clock_pin|
        toggle_ary.push("#{name}") if clock_pin.next_edge == cycle_count
      end
      toggle_ary
    end

    def update_running_clocks
      clocks_running.each do |name, clock_pin|
        clock_pin.update_clock
      end
    end

    def transaction
      yield
      true
    end

    def source_memory_config
      @source_memory_config ||= {}
    end

    def capture_memory_config
      @capture_memory_config ||= {}
    end

    # Configure source memory to a non-default setting
    #
    # This method changes the way the instruments statement gets rendered
    # if the tester's source memory is used.
    #
    # @example
    #   tester.source_memory :default do |mem|
    #     mem.pin :tdi, size: 32, format: :long
    #   end
    #
    # If called without a block, this method will return
    # the instance of type OrigenTesters::MemoryStyle for
    # the corresponding memory type
    #
    # @example
    #   mem_style = tester.source_memory(:default)
    #   mem_style.contained_pins.each do |pin|
    #     attributes_hash = mem_style.accumulate_attributes(pin)
    #
    #   end
    def source_memory(type = :default)
      type = :subroutine if type == :default
      source_memory_config[type] = OrigenTesters::MemoryStyle.new unless source_memory_config.key?(type)
      if block_given?
        yield source_memory_config[type]
      else
        source_memory_config[type]
      end
    end

    # Configure capture memory to a non-default setting
    #
    # This method changes the way the instruments statement gets rendered
    # if the tester's capture memory is used.
    #
    # @example
    #   tester.capture_memory :default do |mem|
    #     mem.pin :tdo, size: 32, format: :long
    #   end
    #
    # If called without a block, this method will return
    # the instance of type OrigenTesters::MemoryStyle for
    # the corresponding memory type
    #
    # @example
    #   mem_style = tester.capture_memory(:default)
    #   if mem_style.contains_pin?(:tdo)
    #     attributes_hash = mem_style.accumulate_attributes(:tdo)
    #
    #   end
    def capture_memory(type = :default)
      type = :hram if type == :default
      capture_memory_config[type] = OrigenTesters::MemoryStyle.new unless capture_memory_config.key?(type)
      if block_given?
        yield capture_memory_config[type]
      else
        capture_memory_config[type]
      end
    end
  end
end
