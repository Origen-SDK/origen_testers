module OrigenTesters
  module Decompiler
    class Pattern
      module Splitter
        REQUIRED_KEYS = [:pinlist_start, :vectors_start, :vectors_end]
        OPTIONAL_KEYS = [:separator, :vectors_include_start_line, :vectors_include_end_line]

        def section_indices
          @section_indices
        end

        def raw_lines(start, stop, &block)
          retn_lines = []
          _run_line_ = lambda do |line, index, retn_lines, &block|
            if index > stop
              break
            elsif index >= start
              if block_given?
                yield
              else
                retn_lines << line
              end
            end
          end

          if direct_source?
            source.split("\n").map { |l| "#{l}\n" }.each_with_index do |line, index|
              _run_line_.call(line, index, retn_lines, &block)
            end
          else
            File.foreach(source).each_with_index do |line, index|
              _run_line_.call(line, index, retn_lines, &block)
            end
          end
          retn_lines
        end

        def raw_frontmatter
          raw_lines(section_indices[:frontmatter_start], section_indices[:frontmatter_end])
        end

        def raw_pinlist
          raw_lines(section_indices[:pinlist_start], section_indices[:pinlist_end])
        end

        def raw_vectors(&block)
          raw_lines(section_indices[:vectors_start], section_indices[:vectors_end])
        end

        def raw_endmatter
          raw_lines(section_indices[:endmatter_start], section_indices[:endmatter_end])
        end

        def split!
          section_indices = split(splitter_config)

          # Check that we found each section in the pattern.
          if section_indices[:pinlist_start].nil?
            Origen.log.error('Parsing Error!')
            Origen.log.error("Could not locate the pinlist start in pattern #{source}")
            Origen.log.error("Expected a pattern line to match '#{splitter_config[:pinlist_start]}'")

            fail OrigenTesters::Decompiler::ParseError, "Parsing Error! Could not locate the pinlist start in pattern #{source}"
          elsif section_indices[:vectors_start].nil?
            Origen.log.error('Parsing Error!')
            Origen.log.error("Could not locate the vector start in pattern #{source}")
            Origen.log.error("Expected a pattern line to match '#{splitter_config[:vector_start]}'")

            fail OrigenTesters::Decompiler::ParseError, "Parsing Error! Could not locate the vector body in pattern #{source}"
          elsif section_indices[:vectors_end].nil?
            Origen.log.error('Parsing Error!')
            Origen.log.error("Could not locate the vector body end in pattern #{source}")
            Origen.log.error("Expected a pattern line to match '#{splitter_config[:vector_end]}'")

            fail OrigenTesters::Decompiler::ParseError, "Parsing Error! Could not locate the vector body end in pattern #{source}"
          end

          @section_indices = section_indices
          @section_indices
        end

        # Splits the pattern into gour secionts using regexes:
        #  1. Frontmatter
        #  2. Pin List
        #  3. Vectors
        #  4. Endmatter
        # The idea is that each section can be delimited by a line that matches some
        # regex (and is not considered a comment line).
        # The pattern will be read line-by-line, looking for the regexes.
        # We're defining the pattern section as such:
        #  - Frontmatter starts at the beginning of the pattern and ends at the start of the pattern header.
        #  - Vectors start from the end of the pattern header and go until the end of the vectors.
        #  - Endmatter starts at the end of the vectors and ends at the end of the file.
        #    - Its possible (and fine) for endmatter to be non-existant, or even not allowed.
        #    - In the latter case, the endvector symbol should the EoF symbol.
        # @return (Hash)
        # rubocop:disable Metrics/ParameterLists
        def split(pinlist_start:, vectors_start:, vectors_end:, vectors_include_start_line: false, vectors_include_end_line: false, &block)
          def check_match(matcher, line, index, indices)
            if matcher.respond_to?(:call)
              matcher.call(line: line, index: index, current_indices: indices)
            elsif matcher.is_a?(Regexp)
              line =~ matcher
            elsif matcher.is_a?(String)
              line.start_with?(matcher)
            else
              fail "Splitter does not know how to match given matcher of class #{matcher.class}"
            end
          end

          if File.zero?(source)
            Origen.log.error('Parsing Error!')
            Origen.log.error("Pattern #{source} has size zero!")
            Origen.log.error('Decompiling empty files is not supported.')

            fail(OrigenTesters::Decompiler::ParseError, "Empty or non-readable pattern file #{source}")
          end

          indices = {
            frontmatter_start: 0,
            endmatter_end:     -1
          }
          if block_given?
            fail 'Blocks are not yet supported!'
          else
            if vectors_end == -1
              indices[:vectors_end] = -1
              indices[:endmatter_start] = -1
            end
            _split_ = lambda do |line, index, indices|
              if !indices[:pinlist_start]
                if check_match(pinlist_start, line, index, indices)
                  indices[:frontmatter_end] = index - 1
                  indices[:pinlist_start] = index
                end
              elsif !indices[:vectors_start]
                if check_match(vectors_start, line, index, indices)
                  indices[:pinlist_end] = index - 1
                  vectors_include_start_line ? indices[:vectors_start] = index : indices[:vectors_start] = index + 1
                end
              elsif !indices[:vectors_end]
                if check_match(vectors_end, line, index, indices)
                  vectors_include_end_line ? indices[:vectors_end] = index : indices[:vectors_end] = index - 1
                  indices[:endmatter_start] = index
                end
              end
            end

            if direct_source?
              source.split("\n").each_with_index do |line, index|
                _split_.call(line, index, indices)
              end
            else
              File.foreach(source).each_with_index do |line, index|
                _split_.call(line, index, indices)
              end
            end

            indices
          end
          # rubocop:enable Metrics/ParameterLists
        end
      end
    end
  end
end
