module OrigenTesters
  module SmartestBasedTester
    module SMT8
      # This currently defines what subdirectory of the pattern output directory that
      # patterns will be output to
      def subdirectory
        File.join(package_namespace, 'patterns')
      end

      # An internal method called by Origen to create the pattern header
      def pattern_header(options = {})
        options = {
        }.merge(options)
        @program_lines = []
        @program_action_lines = []
        if zip_patterns
          @program_lines << '<?xml version="1.0" encoding="UTF-8"?>'
          @program_lines << '<Program xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="Program.xsd">'
        end
        @program_lines << '  <Assignment id="memory" value="SM"/>'
        pin_list = ordered_pins.map do |p|
          if Origen.app.pin_pattern_order.include?(p.id)
            # specified name overrides pin name
            if (p.is_a?(Origen::Pins::PinCollection)) || p.id != p.name
              p.id.to_s # groups or aliases can be lower case
            else
              p.id.to_s.upcase # pins must be uppercase
            end
          else
            if (p.is_a?(Origen::Pins::PinCollection)) || p.id != p.name
              p.name.to_s # groups or aliases can be lower case
            else
              p.name.to_s.upcase # pins must be uppercase
            end
          end
        end.join(',')
        @program_lines << "  <Instrument id=\"#{pin_list}\">"
      end

      # An internal method called by Origen to generate the pattern footer
      def pattern_footer(options = {})
        options = {
          end_in_ka:      false
        }.merge(options)
        if options[:end_in_ka]
          Origen.log.warning '93K keep alive not yet implemented!'
          ss 'WARNING: 93K keep alive not yet implemented!'
        end
        @program_footer_lines = []
        @program_footer_lines << '</Program>' if zip_patterns
      end

      # @api private
      def open_and_write_pattern(filename)
        pat_name = Pathname.new(filename).basename.to_s

        @gen_vec = 0
        @vector_number = 0
        @vector_lines = []
        @comment_lines = []
        # @program_lines was already created with the pattern_header

        yield

        write_gen_vec
        @program_lines << '  </Instrument>'

        if zip_patterns
          tmp_dir = filename.gsub('.', '_')
          FileUtils.mkdir_p(tmp_dir)
          program_file = File.join(tmp_dir, 'Program.sprg')
          vector_file = File.join(tmp_dir, 'Vectors.vec')
          comments_file = File.join(tmp_dir, 'Comments.cmt')

          File.open(program_file, 'w') do |f|
            (@program_lines + @program_action_lines + @program_footer_lines).each do |line|
              f.puts line
            end
          end

          File.open(vector_file, 'w') { |f| @vector_lines.each { |l| f.puts l } }
          File.open(comments_file, 'w') { |f| @comment_lines.each { |l| f.puts l } }

          Dir.chdir tmp_dir do
            `zip #{pat_name} Program.sprg Vectors.vec Comments.cmt`
            FileUtils.mv pat_name, filename
          end
        else
          File.open filename, 'w' do |f|
            f.puts '<Pattern>'
            f.puts '  <Program>'
            (@program_lines + @program_action_lines + @program_footer_lines).each do |line|
              f.puts '  ' + line
            end
            f.puts '  </Program>'
            f.puts '  <Vector>'
            @vector_lines.each { |l| f.puts '    ' + l }
            f.puts '  </Vector>'
            f.puts '  <Comment>'
            @comment_lines.each { |l| f.puts '    ' + l }
            f.puts '  </Comment>'
            f.puts '</Pattern>'
          end
        end
      ensure
        FileUtils.rm_rf(tmp_dir) if zip_patterns && File.exist?(tmp_dir)
      end

      # @api private
      #
      # The SMT8 microcode is implemented as a post conversion of the SMT7 microcode, rather than
      # generating SMT8 microcode originally.
      # This is generally an easier implementation and since they both run on the same h/ware there
      # should always be a 1:1 feature mapping between the 2 systems.
      def track_and_format_comment(comment)
        if comment =~ /^SQPG/
          if comment =~ /^SQPG PADDING/
            # A gen vec should not be used for MRPT vectors, the padding instruction marks the end of them
            @gen_vec = 0
          else
            write_gen_vec
            if comment =~ /^SQPG JSUB ([^;]+);/
              @program_lines << "    <Instruction id=\"patternCall\" value=\"#{tester.package_namespace}.patterns.#{Regexp.last_match(1)}\"/>"
            elsif comment =~ /^SQPG MACT (\d+);/
              if @max_wait_in_time
                time_unit = 's'
                wait_time = 0
                @max_wait_in_time_options.each do |key, value|
                  if key =~ /time_in_/ && value != 0
                    time_unit = key.to_s.gsub('time_in_', '')
                    wait_time = value
                  end
                end
                @program_lines << "    <Instruction id=\"match\" value=\"#{wait_time} #{time_unit}\">"
              else
                @program_lines << "    <Instruction id=\"match\" value=\"#{Regexp.last_match(1)}\">"
              end
              @program_lines << "       <Assignment id=\"matchMode\" value=\"#{match_continue_on_fail ? 'continueOnFail' : 'stopOnFail'}\"/>"
              if @match_inverted
                @program_lines << "       <Assignment id=\"inverted\" value=\"true\"/>"
              end
              @program_lines << '    </Instruction>'
            elsif comment =~ /^SQPG MRPT (\d+);/
              if @max_wait_in_time
                @no_vector_group_close_required = true
              end
              @program_lines << "    <Instruction id=\"matchRepeat\" value=\"#{Regexp.last_match(1)}\"/>"
            elsif comment =~ /^SQPG LBGN (\d+);/
              @program_lines << "    <Instruction id=\"loop\" value=\"#{Regexp.last_match(1)}\"/>"
            elsif comment =~ /^SQPG LEND;/
              @program_lines << "    <Instruction id=\"loopEnd\"/>"
            elsif comment =~ /^SQPG RETC (\d) (\d);/
              @program_lines << "    <Instruction id=\"returnConditional\">"
              @program_lines << "      <Assignment id=\"onFail\" value=\"#{Regexp.last_match(1) == '0' ? 'false' : 'true'}\"/>"
              @program_lines << "      <Assignment id=\"resetFail\" value=\"#{Regexp.last_match(2) == '0' ? 'false' : 'true'}\"/>"
              @program_lines << '    </Instruction>'
            else
              Origen.log.warning "This SMT7 microcode was not converted to SMT8: #{comment}"
            end
          end
        end
      end

      # This is an internal method use by Origen which returns a fully formatted vector
      # You can override this if you wish to change the output formatting at vector level
      def format_vector(vec)
        has_microcode = vec.microcode && !vec.microcode.empty?
        has_repeat = vec.repeat && vec.repeat > 1
        if has_microcode || has_repeat
          # Close out current gen_vec group
          write_gen_vec
          if has_repeat && !@no_vector_group_close_required
            @program_lines << "    <Instruction id=\"genVec\" value=\"1\">"
            @program_lines << "      <Assignment id=\"repeat\" value=\"#{vec.repeat}\"/>"
            @program_lines << '    </Instruction>'
            @gen_vec -= 1
          end
          if has_microcode
            puts vec.microcode
          end
        end

        unless Origen.mode.simulation? || !inline_comments || $_testers_no_inline_comments
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
          # comment += header_comments.join("\cm") unless header_comments.empty?
          # Seems that SMT8 does not support the above newline char, so identify split lines with something else
          comment += header_comments.join('----') unless header_comments.empty?
          unless vec.inline_comment.empty?
            comment += "\cm" unless header_comments.empty?
            comment += "(#{vec.inline_comment})"
          end
          c = "#{repeat_comment}#{comment}"
          @comment_lines << "#{@vector_number} #{c}"[0, 3000] unless c.empty?
        end

        if vec.pin_vals
          @vector_lines << vec.pin_vals.gsub(' ', '')
          @vector_number += 1
          @gen_vec += 1
        end
      end

      # @api private
      def write_gen_vec
        if @gen_vec > 0
          @program_lines << "    <Instruction id=\"genVec\" value=\"#{@gen_vec}\"/>"
          @gen_vec = 0
        end
      end
    end
  end
end
