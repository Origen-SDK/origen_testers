module OrigenTesters
  module LabVIEWBasedTester
    class Pxie6570
      include OrigenTesters::VectorBasedTester

      def initialize
        @pat_extension = 'digipatsrc'
      end

      def pattern_header(options = {})
        microcode 'file_format_version 1.0;'
        called_timesets.each do |timeset|
          microcode "timeset #{timeset.name};"
        end
        pin_list = ordered_pins.map(&:name).join(',')
        microcode "pattern #{options[:pattern]} (#{pin_list})"
        microcode '{'
      end

      def pattern_footer(options = {})
        cycle microcode: 'halt'
        microcode '}'
      end

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

      def store(*pins)
        # not yet implemented
      end
      alias_method :capture, :store
    end
  end
  Pxie6570 = LabVIEWBasedTester::Pxie6570
end
