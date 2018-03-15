module OrigenTesters
  module SmartestBasedTester
    module SMT7
      # This is an internal method use by Origen which returns a fully formatted vector
      # You can override this if you wish to change the output formatting at vector level
      def format_vector(vec)
        timeset = vec.timeset ? "#{vec.timeset.name}" : ''
        pin_vals = vec.pin_vals ? "#{vec.pin_vals} " : ''
        if vec.repeat # > 1
          microcode = "R#{vec.repeat}"
        else
          microcode = vec.microcode ? vec.microcode : ''
        end

        if Origen.mode.simulation? || !inline_comments || $_testers_no_inline_comments
          comment = ''
        else

          header_comments = []
          repeat_comment = ''
          vec.comments.each_with_index do |comment, i|
            if comment =~ /^#/
              if comment =~ /^#(R\d+)$/
                repeat_comment = Regexp.last_match(1) + ' '
              # Throw away the ############# headers and footers
              elsif comment !~ /^# ####################/
                comment = comment.strip.sub(/^# (## )?/, '')
                if comment == ''
                  # Throw away empty lines at the start/end, but preserve them in the middle
                  unless header_comments.empty? || i == vec.comments.size - 1
                    header_comments << comment
                  end
                else
                  header_comments << comment
                end
              end
            end
          end

          if vec.pin_vals && ($_testers_enable_vector_comments || vector_comments)
            comment = "#{vec.number}:#{vec.cycle}"
            comment += ': ' if !header_comments.empty? || !vec.inline_comment.empty?
          else
            comment = ''
          end
          comment += header_comments.join("\cm") unless header_comments.empty?
          unless vec.inline_comment.empty?
            comment += "\cm" unless header_comments.empty?
            comment += "(#{vec.inline_comment})"
          end
          comment = "#{repeat_comment}#{comment}"
        end

        # Max comment length 250 at the end
        "#{microcode.ljust(25)}#{timeset.ljust(27)}#{pin_vals}# #{comment[0, 247]};"
      end
    end
  end
end
