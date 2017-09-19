module OrigenTesters
  module LabVIEWBasedTester
    class Pxie6570
      include OrigenTesters::VectorBasedTester

      def initialize
        @pat_extension = 'digipatsrc'
        @capture_started = {}
        @source_started = {}
      end

      # Internal method called by Origen
      def pattern_header(options = {})
        microcode 'file_format_version 1.0;'
        called_timesets.each do |timeset|
          microcode "timeset #{timeset.name};"
        end
        pin_list = ordered_pins.map(&:name).join(',')
        microcode "pattern #{options[:pattern]} (#{pin_list})"
        microcode '{'
      end

      # Internal method called by Origen
      def pattern_footer(options = {})
        # add capture/source stop to the end of the pattern
        cycle microcode: 'capture_stop' if @capture_started[:default]
        cycle microcode: 'halt'
        microcode '}'
      end

      # Internal method called by Origen
      def format_vector(vec)
        timeset = vec.timeset ? " #{vec.timeset.name}" : ''
        pin_vals = vec.pin_vals ? "#{vec.pin_vals} ;" : ''
        if vec.repeat > 1
          microcode = "repeat (#{vec.repeat})"
        else
          microcode = vec.microcode ? vec.microcode : ''
        end
        if vec.pin_vals && ($_testers_enable_vector_comments || vector_comments)
          comment = " // #{vec.number}:#{vec.cycle} #{vec.inline_comment}"
        else
          comment = vec.inline_comment.empty? ? '' : " // #{vec.inline_comment}"
        end

        "#{microcode.ljust(65)}#{timeset.ljust(31)}#{pin_vals}#{comment}"
      end

      def call_subroutine(name, options = {})
        # not yet implemented
      end

      # store/capture the state of the provided pins
      def store(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = { offset: 0 }.merge(options)
        pins = pins.flatten.compact

        fail 'For the PXIE6570 you must supply the pins to store/capture' if pins.empty?
        unless @capture_started[:default]
          # add the capture start opcode to the top of the pattern
          stage.insert_from_start 'capture_start(default_capture_waveform)', 0
          @capture_started[:default] = true
        end

        pins.each do |pin|
          pin.restore_state do
            pin.capture
            update_vector_pin_val pin, offset: options[:offset]
            last_vector(options[:offset]).dont_compress = true
          end
        end

        update_vector microcode: 'capture', offset: options[:offset]
      end
      alias_method :to_hram, :store
      alias_method :capture, :store

      def cycle(options = {})
        options.delete(:overlay)
        super(options)
      end

      # store/capture the provided pins on the next cycle
      def store_next_cycle(*pins)
        options = pins.last.is_a?(Hash) ? pins.pop : {}
        options = { offset: 0 }.merge(options)
        pins = pins.flatten.compact

        fail 'For the PXIE6570 you must supply the pins to store/capture' if pins.empty?
        unless @capture_started[:default]
          # add the capture start opcode to the top of the pattern
          stage.insert_from_start 'capture_start(default_capture_waveform)', 0
          @capture_started[:default] = true
        end

        pins.each { |pin| pin.save; pin.capture }
        preset_next_vector(microcode: 'capture') do
          pins.each(&:restore)
        end
      end
      alias_method :store!, :store_next_cycle

      # add a label to the output pattern
      def label(name, global = false)
        microcode name + ':'
      end
    end
  end
  Pxie6570 = LabVIEWBasedTester::Pxie6570
end
