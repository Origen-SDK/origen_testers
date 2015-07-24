require 'active_support/concern'
module OrigenTesters
  module VectorGenerator
    extend ActiveSupport::Concern

    require 'erb'

    included do
      # When set to true vector and cycle number comments will be appended to pattern vectors.
      # This can also be enabled by running the generate command with the '-v' switch.
      attr_accessor :vector_comments
      attr_accessor :compress
      attr_accessor :expand_repeats
    end

    def vector_group_size
      @vector_group_size || 1
    end

    def vector_group_size=(number)
      if number > 1 && number.odd?
        fail 'Only even numbers can be supplied for the vector_group_size!'
      end
      # Each pattern should run with its own tester instance, but just in case
      @pipeline = nil
      @vector_group_size = number
    end

    def with_vector_group_size(number)
      orig = vector_group_size
      self.vector_group_size = number
      yield
      self.vector_group_size = orig
    end

    # Duplicate the last vector as required until aligned with the start of the
    # next vector group
    def align
      stage.store :align
    end
    alias_method :align_to_first, :align

    # Duplicate the last vector as required until aligned to the last vector of the
    # current vector group
    def align_to_last
      stage.store :align_last
    end

    # Returns an array of pin IDs that are currently inhibited (will not
    # be included when vectors are generated)
    def inhibited_pins
      @inhibited_pins ||= []
    end

    # init vector count when first accessed, otherwise return value
    def vec_count
      @vec_count ||= 0
    end

    # increment vector count
    def inc_vec_count(num = 1)
      vec_count if @vec_count.nil?  # define if not already
      @vec_count = @vec_count + num
    end

    # decrement vector count
    def dec_vec_count(num = 1)
      vec_count if @vec_count.nil?  # define if not already
      @vec_count = @vec_count - num
    end

    # init cycle count when first accessed, otherwise return value
    def cycle_count
      @cycle_count ||= 0
    end

    # increment cycle count
    def inc_cycle_count(num = 1)
      cycle_count if @cycle_count.nil? # define if not already
      @cycle_count = @cycle_count + num
    end

    # reset_cycle_count
    def reset_cycle_count(num = 0)
      cycle_count if @cycle_count.nil? # define if not already
      @cycle_count = num
    end

    # Call to prevent the given pins from appearing in the generated vectors.
    #
    # This is a convenient way to inhibit something like a J750 mux pin from
    # appearing in the patterns when generating the pattern for a different
    # platform.
    #
    # When used this
    # method must be called before the first vector is generated - it will not be retrospectively
    # applied to existing vectors.
    def inhibit_pin(*pins)
      pins.each do |pin|
        pin = $dut.pin(pin) if pin.is_a?(Symbol)
        inhibited_pins << pin
      end
      inhibited_pins.uniq!
      inhibited_pins.compact!
      inhibited_pins
    end
    alias_method :inhibit_pins, :inhibit_pin

    # Render content directly into a pattern, any options will be passed to the template
    def render(template, options = {})
      # Record the current file, this can be used to resolve any relative path
      # references in the file about to be compiled
      Origen.file_handler.current_file = template
      # Ran into crosstalk problems when rendering ERB templates recursively, setting eoutvar based
      # on the name of the file will causes each template to be rendered into its own 'bank'.
      # Not sure why the final gsub is needed but seems to fail to parse correctly otherwise.
      eoutvar = Pathname.new(template).basename('.*').basename('.*').to_s.gsub('-', '_')
      # Make the file name available to the template
      Origen.generator.compiler.options[:file] = template
      options.each { |k, v| Origen.generator.compiler.options[k] = v }
      code = Origen.generator.compiler.insert(ERB.new(File.read(template.to_s), 0, Origen.config.erb_trim_mode, eoutvar).result)
      code.strip!
      push_microcode code
    end

    # If the tester defines a method named template this method will compile
    # whatever template file is returned by that method.
    #
    # This method is called automatically after the body section of a Pattern.create
    # operation has completed.
    def render_template
      _render(:template)
    end

    # Same as the render method, except the template method should be called body_template.
    def render_body
      _render(:body_template)
    end

    # If the tester defines a method named footer_template this method will compile
    # whatever template file is returned by that method.
    #
    # This method is called automatically during the footer section of a Pattern.create
    # operation.
    def render_footer
      _render(:footer_template)
    end

    # If the tester defines a method named header_template this method will compile
    # whatever template file is returned by that method.
    #
    # This method is called automatically during the header section of a Pattern.create
    # operation.
    def render_header
      _render(:header_template)
    end

    def _render(method)  # :nodoc:
      if self.respond_to?(method)
        template = send(method)
        # Record the current file, this can be used to resolve any relative path
        # references in the file about to be compiled
        Origen.file_handler.current_file = template
        # Ran into crosstalk problems when rendering ERB templates recursively, setting eoutvar based
        # on the name of the file will causes each template to be rendered into its own 'bank'.
        # Not sure why the final gsub is needed but seems to fail to parse correctly otherwise.
        eoutvar = Pathname.new(template).basename('.*').basename('.*').to_s.gsub('-', '_')
        # Make the file name available to the template
        Origen.generator.compiler.options[:file] = template
        push_microcode Origen.generator.compiler.insert(ERB.new(File.read(template.to_s), 0, Origen.config.erb_trim_mode, eoutvar).result)
      end
    end

    def stage
      Origen.generator.stage
    end

    def push_comment(msg)
      # Comments are stored verbatim for now, can't see much use for a dedicated comment object
      stage.store msg unless @inhibit_comments
    end

    def microcode(code, options = {})
      unless @inhibit_vectors
        if options[:offset] && options[:offset] != 0
          stage.insert_from_end code, options[:offset]
        else
          stage.store code
        end
      end
    end
    alias_method :push_microcode, :microcode

    def last_vector(offset = 0)
      stage.last_vector(offset)
    end

    def last_object(offset = 0)
      stage.last_object(offset)
    end

    # Allows the attributes for the next vector to be setup prior
    # to generating it.
    #
    # A block can be optionally supplied to act as a clean up method,
    # that is the block will be saved and executed after the next
    # cycle has been generated.
    #
    # See the V93K store_next_cycle method for an example of using
    # this.
    def preset_next_vector(attrs = {}, &block)
      @preset_next_vector = attrs
      @preset_next_vector_cleanup = block
    end

    # Called by every $tester.cycle command to push a vector to the stage object
    def push_vector(attrs = {})
      attrs = {
        dont_compress: @dont_compress
      }.merge(attrs)
      unless @inhibit_vectors
        if @preset_next_vector
          attrs = @preset_next_vector.merge(attrs) do |key, preset, current|
            if preset && current && current != ''
              fail "Value for #{key} set by preset_next_vector clashed with the next vector!"
            else
              preset || current
            end
          end
          @preset_next_vector = nil
        end
        stage.store Vector.new(attrs)
        inc_vec_count
        inc_cycle_count(attrs[:repeat] || 1)
        if @preset_next_vector_cleanup
          @preset_next_vector_cleanup.call
          @preset_next_vector_cleanup = nil
        end
      end
    end
    alias_method :vector, :push_vector

    def update_vector(attrs = {})
      unless @inhibit_vectors
        offset = (attrs.delete(:offset) || 0).abs
        stage.last_vector(offset).update(attrs)
      end
    end

    def update_vector_pin_val(pin, options = {})
      unless @inhibit_vectors
        offset = (options.delete(:offset) || 0).abs
        stage.last_vector(offset).update_pin_val(pin)
      end
    end

    # Adds the given microcode to the last vector if possible. If not possible (meaning the
    # vector already contains microcode) then a new cycle will be added with the given
    # microcode.
    def add_microcode_to_last_or_cycle(code)
      cycle if !stage.last_vector || stage.last_vector.has_microcode?
      stage.last_vector.update(microcode: code)
    end

    # Final pass of a generator vector array which returns lines suitable for writing to the
    # output file. This gives the tester model a chance to concatenate repeats and any other
    # last optimization/formatting changes it wishes to make.
    #
    # At this point vector array contains a combination of non-vector lines and uncompressed
    # Vector objects (vector lines)
    #
    def format(vector_array, section)
      # Go through vector_array and print out both
      # vectors and non-vectors to pattern (via 'yield line')
      vector_array.each do |vec|
        # skip here important for the ways delays are currently handled
        # TODO: This seems like an upstream bug that should be investigated, why is such
        # a vector even generated?
        if vec.is_a?(String)
          if vec.strip[0] == comment_char
            pipeline.push_comment(vec)
          else
            pipeline.push_microcode(vec)
          end
        else
          next if vec.respond_to?(:repeat) && vec.repeat == 0 # skip vectors with repeat of 0!
          pipeline << vec
        end
        pipeline.flush do |vector|
          expand_vector(vector) do |line|
            yield line
          end
        end
      end
      # now flush buffer if there is still a vector
      pipeline.empty(min_vectors: section == :footer ? @min_pattern_vectors : nil) do |vector|
        expand_vector(vector) do |line|
          yield line
        end
      end
    end

    # Tester models can overwrite this if they wish to inject any additional pattern lines
    # at final pattern dump time
    def before_write_pattern_line(line)
      [line]
    end

    def pipeline
      @pipeline ||= VectorPipeline.new(vector_group_size)
    end

    def dont_compress
      if block_given?
        orig = @dont_compress
        @dont_compress = true
        yield
        @dont_compress = orig
      else
        @dont_compress
      end
    end

    def dont_compress=(val)
      @dont_compress = val
    end

    # expands (uncompresses to pattern) vector if desired or leaves it as is
    # allows for tracking and formatting of vector
    # if comment then return without modification
    def expand_vector(vec)
      if vec.is_a?(Vector)
        if expand_repeats
          vec.repeat.times do
            vec.repeat = 1
            yield track_and_format_vector(vec)
          end
        else
          yield track_and_format_vector(vec)
        end
      else
        yield vec  # Return comments without modification
      end
    end

    # Update tracking info (stats object) and allow for
    # any additional formatting via format_vector
    # method if overridden
    def track_and_format_vector(vec)
      unless vec.timeset
        puts 'No timeset defined!'
        puts 'Add one to your top level startup method or target like this:'
        puts '$tester.set_timeset("nvmbist", 40)   # Where 40 is the period in ns'
        exit 1
      end
      stats = Origen.app.stats
      stats.add_vector
      if vector_group_size > 1 && vec.repeat > 1
        stats.add_cycle(1)
        stats.add_cycle((vec.repeat - 1) * vector_group_size)
        stats.add_time_in_ns(vec.timeset.period_in_ns)
        stats.add_time_in_ns((vec.repeat - 1) * vector_group_size * vec.timeset.period_in_ns)
      else
        stats.add_cycle(vec.repeat)
        stats.add_time_in_ns(vec.repeat * vec.timeset.period_in_ns)
      end
      format_vector(vec)
    end

    def format_vector(vec)
    end

    def pingroup_map
      Origen.app.pingroup_map
    end

    # Cache any pin ordering for later use since all vectors should be formatted the same
    def ordered_pins_cache(options = {})
      @ordered_pins_cache ||= ordered_pins(options)
    end

    def ordered_pins(options = {})
      options = {
        include_inhibited_pins: false,
        include_pingroups:      true
      }.merge(options)

      pinorder = Origen.app.pin_pattern_order.dup
      pinexclude = Origen.app.pin_pattern_exclude.dup
      pinids = []

      if Origen.app.pin_pattern_order.last.is_a?(Hash)
        options.merge!(pinorder.pop)
      end
      if Origen.app.pin_pattern_exclude.last.is_a?(Hash)
        options.merge!(pinexclude.pop)
      end

      ordered_pins = []

      # add bit here that puts pingroup id into ordered pins array and deletes included pins
      pins = Origen.pin_bank.pins.dup
      pingroups = Origen.pin_bank.pin_groups.dup

      if pinorder && pinorder.size > 0
        pinorder.each do |id|
          if Origen.pin_bank.pin_groups.keys.include? id
            # see if group is already in ordered_pins
            fail "Pin group #{id} is duplicately defined in pin_pattern_order" unless pingroups.include? id
            # see if any pins in group are already in pin_order
            used = []
            pingroups[id].each do |pin|
              pinorder.each { |pin| pinids << Origen.pin_bank.find(pin).id if Origen.pin_bank.find(pin) }
              used << pin if pinids.include?(pin.id) # see if pin included in pinids
            end
            if !used.empty?
              pingroups[id].each { |pin| ordered_pins << pin unless used.include?(pin) }
            else
              # this is a pin group, add pin_group and delete all pins in group
              ordered_pins << pingroups[id]
              pingroups[id].each do |pin|
                fail "Pin (#{pin.name}) in group (#{id}) is duplicately defined in pin_pattern_order" unless pins.include? pin.id
                pins.delete(pin.id)
              end
            end
            pingroups.delete(id)
          else # this is a pin
            pin = Origen.pin_bank.find(id)
            fail "Undefined pin (#{id}) added to pin_pattern_order" unless pin
            ordered_pins << pin
            pin.name = id
            fail "Individual pin (#{pin.name}) is duplicately defined in pin_pattern_order" unless pins.include? pin.id
            pins.delete(pin.id)
          end
        end
      end

      if pinexclude && pinexclude.size > 0
        pinexclude.each do |id|
          if Origen.pin_bank.pin_groups.keys.include? id
            # see if group is already in ordered_pins
            fail "Pin group #{id} is defined both in pin_pattern_order and pin_pattern_exclude" unless pingroups.include? id
            # this is a pin group, delete all pins in group
            pingroups[id].each do |pin|
              fail "Pin (#{pin.name}) in group (#{id}) is defined both in pin_pattern_order and pin_pattern_exclude" unless pins.include? pin.id
              pins.delete(pin.id)
            end
          else # this is a pin, delete the pin
            pin = Origen.pin_bank.find(id)
            fail "Undefined pin (#{id}) added to pin_pattern_exclude" unless pin
            fail "Pin #{pin.name} is defined both in pin_pattern_order and pin_pattern_exclude" unless pins.include? pin.id
            pin.name = id
            pins.delete(pin.id)
          end
        end
      end

      unless options[:only]
        # all the rest of the pins to the end of the pattern order
        pins.each do |id, pin|
          # check for port
          if pin.belongs_to_a_pin_group?
            if id =~ /(\D+)\d+$/
              name = Regexp.last_match[1]
              port = nil
              pin.groups.each do |group|
                if group[0] == name.to_sym # belongs to a port
                  port = group[1]
                end
              end
              if pingroups.include?(port.id)
                ordered_pins << port
                port.each { |pin| pins.delete(pin.id) }
              end
            else
              ordered_pins << pin
            end
          else
            ordered_pins << pin
          end
        end
      end

      ordered_pins.map do |pin|
        if options[:include_inhibited_pins]
          pin
        else
          inhibited_pins.include?(pin) ? nil : pin
        end
      end.compact
    end

    def current_pin_vals
      ordered_pins_cache.map(&:to_vector).join(' ')
    end

    # Returns a regular expression that can be used to get the value
    # of the given pin within the string returned by current_pin_vals.
    #   str = $tester.current_pin_vals                  # => "1 1 XX10 H X1"
    #   regex = $tester.regex_for_pin($dut.pins(:jtag)) # => /\w{1} \w{1} (\w{4}) \w{1} \w{2}/
    #   regex.match(str)
    #   Regexp.last_match(1)   # => "XX10"
    #
    # @see Vector#pin_value
    def regex_for_pin(pin)
      @regex_for_pins ||= {}
      # Cache this as potentially called many times during pattern generation
      @regex_for_pins[pin] ||= begin
        regex = '/'
        ordered_pins_cache.each do |p|
          if pin == p
            regex += "(\\w{#{p.size}}) "
          else
            regex += "\\w{#{p.size}} "
          end
        end
        eval(regex.strip + '/')
      end
    end

    # Returns a regular expression that can be used to change the value
    # of the given pin within the string returned by current_pin_vals.
    #   str = $tester.current_pin_vals                      # => "1 1 XX10 H X1"
    #   regex = $tester.regex_for_pin_sub($dut.pins(:jtag)) # => /(\w{1} \w{1} )(\w{4})( \w{1} \w{2})/
    #   str.sub(regex, '\1LLLL\3')  # => "1 1 LLLL H X1"
    #
    # @see Vector#set_pin_value
    def regex_for_pin_sub(pin)
      @regex_for_pin_subs ||= {}
      # Cache this as potentially called many times during pattern generation
      @regex_for_pin_subs[pin] ||= begin
        regex = '/'
        first_pin_done = false
        match_pin_done = false
        ordered_pins_cache.each do |p|
          if pin == p
            regex += ')' if first_pin_done
            regex += "(\\w{#{p.size}})( "
          else
            regex += '(' unless first_pin_done
            regex += "\\w{#{p.size}} "
          end
          first_pin_done = true
        end
        regex.strip!
        if regex[-1] == '('
          regex.chop!
        else
          regex += ')'
        end
        eval(regex + '/')
      end
    end

    def get_pingroup(pin)
      pingroup_map.each do |id, pins|
        return id if pins.include? pin
      end
      nil
    end

    def update_pin_from_formatted_state(pin, state)
      if state == @repeat_previous || state == '-'
        pin.repeat_previous = true
      elsif state == @drive_very_hi_state || state == '2'
        pin.drive_very_hi
      elsif state == @drive_hi_state || state == '1'
        pin.drive_hi
      elsif state == @drive_lo_state || state == '0'
        pin.drive_lo
      elsif state == @expect_hi_state || state == 'H'
        pin.expect_hi
      elsif state == @expect_lo_state || state == 'L'
        pin.expect_lo
      elsif state == @expect_mid_state || state == 'M'
        pin.expect_mid
      elsif state == @drive_mem_state || state == 'D'
        pin.drive_mem
      elsif state == @expect_mem_state || state == 'E'
        pin.expect_mem
      elsif state == @capture_state || state == 'C'
        pin.capture
      elsif state == @dont_care_state || state == 'X'
        pin.dont_care
      else
        fail "Unknown pin state: #{state}"
      end
    end

    # @see Origen::Pins::Pin#to_vector
    def format_pin_state(pin)
      if pin.repeat_previous? && @support_repeat_previous
        @repeat_previous || '-'
      elsif pin.driving?
        if pin.value == 1
          if pin.high_voltage?
            @drive_very_hi_state || '2'
          else
            @drive_hi_state || '1'
          end
        else
          @drive_lo_state || '0'
        end
      elsif pin.comparing_midband?
        @expect_mid_state || 'M'
      elsif pin.comparing?
        if pin.value == 1
          @expect_hi_state || 'H'
        else
          @expect_lo_state || 'L'
        end
      elsif pin.driving_mem?
        @drive_mem_state || 'D'
      elsif pin.comparing_mem?
        @expect_mem_state || 'E'
      elsif pin.to_be_captured?
        @capture_state || 'C'
      else
        @dont_care_state || 'X'
      end
    end
  end
end
