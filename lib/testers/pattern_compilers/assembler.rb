module Testers
  module PatternCompilers
    class UltraFlexPatternCompiler
      private

      # Check the file extension of a file, return status can be 'atp', 'list', or nil
      def check_file_ext(file)
        status = nil
        ext = file.extname
        name = file.basename
        if ext == '.atp'
          status = 'atp'
        elsif ext == '.gz'
          # Ensure we have a .atp.gz
          sub_ext = name.to_s.split('.')[-2]
          if sub_ext == 'atp'
            status = 'atp'
          end
        elsif ext == '.list'
          status = 'list'
        end
        status
      end

      # Parse a pattern list file recursively until all .atp or .atp.gz files are found
      def parse_list(path, files)
        list_name = path.basename
        dir = path.dirname
        line_number = 0
        path.open('r') do |f|
          while (line = f.gets)
            line_number += 1
            # Strip the leading and trailing whitespace for sloppy typers
            line.strip!
            # Skip a blank line
            next if line.match(/^\s+$/)
            # Check if the pattern or list exists
            line_path = Pathname.new("#{dir}/#{line}")
            unless line_path.file?
              # puts "Skipping #{line_path.to_s} at line ##{line_number} in file #{path.to_s} because it is not a file"
              next
            end
            # Process the file
            process_file(line_path, files)
          end
        end
      end

      # Processes a file looking for a valid .atp or .list
      def process_file(file, files)
        # puts "processing file #{file.to_s}"
        case check_file_ext(file)
          when 'atp'
            files << file unless files.include?(file)
          when 'list'
            parse_list(file, files)
          end
      end

      # Processes a diretcory looking for files in '.' or recursively
      def process_directory(dir, files, rec)
        dir.children(true).each do |f|
          # ignore sub-directories
          if f.directory?
            if rec == false
              next
            else
              process_directory(f.expand_path, files, rec)
            end
          end
          process_file(f.expand_path, files)
        end
      end

      # Deletes the pattern compiler log files
      def clean_output
        @jobs.each do |job|
          logfile = Pathname.new("#{job.pattern.dirname}/#{job.pattern.basename.to_s.chomp(job.pattern.extname)}.log")
          logfile.cleanpath
          if logfile.file?
            # puts "Deleting log file #{logfile}"
            logfile.delete
          end
        end
      end
    end
  end
end
