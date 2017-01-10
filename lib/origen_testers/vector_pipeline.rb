module OrigenTesters
  class VectorPipeline
    attr_reader :group_size, :pipeline
    # Used to keep track of how many vectors since the last reset of the pipeline (i.e.
    # since pattern start). This is used to implement padding if there is a minimum
    # vector requirement.
    attr_reader :vector_count
    attr_reader :cycle_count

    def initialize(group_size)
      @group_size = group_size
      @pipeline = []
      # A new pipeline is instantiated per-pattern, so don't need to worry about
      # clearing this
      @vector_count = 0
      @cycle_count = 0
    end

    def push_comment(comment)
      comments << comment
    end

    def push_microcode(code)
      if $tester.v93k? && code =~ /JSUB/
        @vector_count += 1
      end
      comments << code
    end

    # Add a vector/comment to the pipeline
    def <<(vector)
      if vector.is_a?(Vector)
        level_period(vector) do |vector|
          consume_comments(vector)
          if vector.repeat > 1
            add_repeat_vector(vector)
          else
            pipeline << vector
          end
        end
        # Keep a persistent record of the last vector so that we know what it
        # was after the pipeline has been flushed
        @last_vector = pipeline.last
      elsif vector.is_a?(Symbol)
        case vector
        when :align
          duplicate_last_vector until aligned?
        when :align_last
          duplicate_last_vector until aligned_to_last?
        else
          fail "Uknown vector generator instruction: #{vector}"
        end
      else
        comments << vector
      end
    end

    # If there are complete groups sitting at the top of the pipeline
    # then this will yield them back line by line, stopping after the last
    # complete group and leaving any remaining single vectors in the pipeline
    #
    # If there are no complete groups present then it will just return
    def flush(&block)
      while lead_group_finalized?
        lead_group.each do |vector|
          vector.comments.each do |comment|
            yield comment
          end
          yield_vector(vector, &block)
        end
        pipeline.shift(group_size)
      end
    end

    # Call at the end to force a flush out of any remaining vectors
    def empty(options = {}, &block)
      if !pipeline.empty? || !comments.empty?
        if options[:min_vectors]
          comment_written = false
          while @vector_count < options[:min_vectors] - pipeline.size
            unless comment_written
              yield "#{$tester.comment_char} PADDING VECTORS ADDED TO MEET MIN #{options[:min_vectors]} FOR PATTERN"
              comment_written = true
            end
            yield_vector(@last_vector, &block)
          end
        end
        duplicate_last_vector until aligned?
        pipeline.each do |vector|
          vector.comments.each do |comment|
            yield comment
          end
          yield_vector(vector, &block)
        end

        comments.each do |comment|
          yield comment
        end
        @pipeline = []
        @comments = []
      end
    end

    private

    def yield_vector(vector, &block)
      vector.cycle = @cycle_count
      vector.number = @vector_count
      r = vector.repeat || 1
      if $tester.min_repeat_loop && r < $tester.min_repeat_loop
        vector.repeat = 1
        if r > 1
          vector.comments << '#R' + r.to_s
        end
        yield vector
        (r - 1).times do |index|
          vector.comments = ['#R' + (r - 1 - index).to_s]
          vector.number += 1
          vector.cycle += 1
          yield vector
        end
        @vector_count += r
        @cycle_count += r
      else
        yield vector
        @vector_count += 1
        @cycle_count += r
      end
    end

    def level_period(vector)
      if $tester.level_period?
        vector.convert_to_timeset($tester.min_period_timeset) do |vector|
          yield vector
        end
      else
        yield vector
      end
    end

    # Pushes a duplicate of the given vector with its repeat set to 1
    #
    # Also clears any comments associated with the vector with the rationale that we only
    # want to see them the first time.
    #
    # Any microcode is cleared with the rationale that the caller is responsible for aligning
    # this to the correct vector if required.
    def push_duplicate(vector, options = {})
      v = vector.dup
      v.microcode = nil
      v.repeat = 1
      pipeline << v
      if options[:existing_vector]
        v.comments = []
      else
        vector.comments = []
      end
    end

    def duplicate_last_vector
      v = @last_vector.dup
      v.comments = []
      v.timeset = $tester.timeset
      v.repeat = 1
      v.microcode = nil
      pipeline << v
    end

    def add_repeat_vector(vector)
      count = vector.repeat
      # Align to the start of a new group by splitting off single vectors
      # to complete the current group
      while !aligned? && count > 0
        push_duplicate(vector)
        count -= 1
      end
      if count > group_size
        remainder = count % group_size
        # Create a group with the required repeat
        group_size.times do
          push_duplicate(vector)
        end
        pipeline.last.repeat = (count - remainder) / group_size
        # Then expand out any leftover
        remainder.times do
          push_duplicate(vector)
        end
      # For small repeats that fit within the group just expand them
      else
        while count > 0
          push_duplicate(vector)
          count -= 1
        end
      end
    end

    # Returns true of the next vector to be added to the pipeline will
    # be at the start of a new group
    def aligned?
      (pipeline.size % group_size) == 0
    end

    # Returns true if the next vector to be added to the pipeline will
    # complete the current group
    def aligned_to_last?
      (pipeline.size % group_size) == (group_size - 1)
    end

    def consume_comments(vector)
      vector.comments = comments
      @comments = []
    end

    def comments
      @comments ||= []
    end

    # When true the lead group is complete and a further repeat of it is not possible
    # Calling this will compress the 2nd group into the 1st if possible
    def lead_group_finalized?
      if first_group_present? && second_group_present?
        if second_group_is_duplicate_of_first_group? && first_group_repeat != $tester.max_repeat_loop &&
           first_group_can_be_compressed?
          # Consume the second group by incrementing the first group repeat counter
          self.first_group_repeat = first_group_repeat + second_group_repeat
          # Delete the second group
          group_size.times { pipeline.delete_at(group_size) }

          # Now deal with any overflow of the first group repeat counter
          if first_group_repeat > $tester.max_repeat_loop
            r = first_group_repeat - $tester.max_repeat_loop
            self.first_group_repeat = $tester.max_repeat_loop
            group_size.times { |i| push_duplicate(pipeline[i], existing_vector: true) }
            self.second_group_repeat = r
            true
          elsif first_group_repeat == $tester.max_repeat_loop
            true
          else
            false
          end
        else
          # Second group has started and is already different from the first group
          true
        end
      end
    end

    def first_group_repeat
      # This is currently hardcoded to the Teradyne concept of the repeat being applied
      # to the last vector in the group. May need an abstraction here if other ATEs don't
      # adhere to that approach.
      first_group.last.repeat || 1
    end

    def first_group_repeat=(val)
      first_group.last.repeat = val
    end

    def second_group_repeat
      second_group.last.repeat || 1
    end

    def second_group_repeat=(val)
      second_group.last.repeat = val
    end

    def first_group_can_be_compressed?
      first_group.all? do |vector|
        !vector.dont_compress
      end
    end

    def second_group_is_duplicate_of_first_group?
      i = -1
      second_group.all? do |vector|
        i += 1
        (pipeline[i] == vector) && (vector.comments.size == 0) &&
          # Don't consider vectors with matching microcode duplicates, caller is
          # responsible for laying out microcode with the correct alignment
          !pipeline[i].has_microcode? && !vector.has_microcode? &&
          !vector.dont_compress
      end
    end

    def first_group_present?
      lead_group.size == group_size
    end

    def second_group_present?
      second_group.size == group_size
    end

    def lead_group
      pipeline[0..group_size - 1]
    end
    alias_method :first_group, :lead_group

    def second_group
      pipeline[group_size..(group_size * 2) - 1]
    end
  end
end
