module OrigenTesters
  module Decompiler
    class Pattern
      # We can't use Ruby's enumerable mix-in directly, as our each method
      # isn't a true implementation, as the mix-in expects.
      # Instead, we'll provide our own enumerable methods as needed that use
      # our own each method.
      module EnumerableExt
        # Iterate through the vectors one by one.
        # We'll begin reading the file from the vector start until the regex/block
        # vector_delimiter is met.
        # This delimiter can include multiple lines.
        # Once the delimiter finishes, those lines will be sent to the treetop
        # parser for conversion to an AST.
        # Lastly, the next vector will start where the previous one left off.
        def each(**options, &block)
          unless decompiled?
            Origen.app!.fail(message: 'Pattern has not yet been decompiled! Cannot iterate through vectors or query pattern aspects!')
          end
          vectors_started = false
          delimiter_klass = VectorDelimiterBase
          v = delimiter_klass.new(self)
          vector_index = 0

          if direct_source?
            kickoff = 'source.split("\n")'
          else
            kickoff = 'File.foreach(source)'
          end

          eval(kickoff).each_with_index do |line, index|
            # Get to the point in the file where the vectors begin
            if index > section_indices[:vectors_end] && section_indices[:vectors_end] != -1
              break
            elsif index < section_indices[:vectors_start]
              next
            end

            v.shift(line)
            if v.delimited?
              # index starts at 0, but most file editors start the line numbers at 1.
              yield(_parse_vector_(v.current_vector!, vector_index: vector_index, line: index + 1))
              vector_index += 1

              if v.include_last_line?
                # The last line is included in the current vector.
                v = delimiter_klass.new(self)
              else
                # The last line shouldn't be included in this vector.
                # Shift it into a new one.
                v = delimiter_klass.new(self)
                v.shift(line)

                # Check if this new vector is delimited before grabbing
                # the next line.
                if v.delimited?
                  yield(_parse_vector_(v.current_vector!, vector_index: vector_index))
                  v = delimiter_klass.new(self)
                  vector_index += 1
                end
              end
            end
          end
        end
        alias_method :each_vector, :each

        def each_vector_with_index(&block)
          i = 0
          each_vector do |v|
            yield(v, i)
            i += 1
          end
        end

        def vector_at(index, &block)
          each_vector_with_index do |v, i|
            if i == index
              return v
            end
          end
          nil
        end

        def collect(&block)
          vectors = []
          each_vector do |v|
            if block_given?
              vectors << yield(v)
            else
              vectors << v
            end
          end
          vectors
        end
        alias_method :collect_vectors, :collect
        alias_method :map, :collect
        alias_method :map_vectors, :collect

        def collect_with_index(&block)
          vectors = []
          each_vector_with_index do |v, i|
            if block_given?
              vectors << yield(v, i)
            else
              vectors << v
            end
          end
          vectors
        end
        alias_method :collect_vectors_with_index, :collect_with_index

        def find_all(&block)
          vectors = []
          if block_given?
            each_vector { |v| vectors << v if yield(v) }
          end
          vectors
        end
        alias_method :select, :find_all
        alias_method :filter, :find_all

        def find(&block)
          if block_given?
            each_vector { |v| return v if yield(v) }
          end
        end
        alias_method :detect, :find

        def find_index(&block)
          find(&block).vector_index
        end

        def count(&block)
          cnt = 0
          if block_given?
            each_vector { |v| cnt += 1 if yield(v) }
          else
            each_vector { |v| cnt += 1 }
          end
          cnt
        end
        alias_method :size, :count

        def reject(&block)
          vectors = []
          if block_given?
            each_vector { |v| vectors << v unless yield(v) }
          end
          vectors
        end

        def first(n = nil)
          if n
            if n <= 0
              return nil
            end

            vectors = []
            each_vector_with_index do |v, i|
              vectors << v
              if n == (i - 1)
                return vectors
              end
            end
            vectors
          else
            # this loop will be executed only once
            # rubocop:disable Lint/UnreachableLoop
            each_vector { |v| return v }
            # rubocop:enable Lint/UnreachableLoop
          end
        end
      end
    end
  end
end
