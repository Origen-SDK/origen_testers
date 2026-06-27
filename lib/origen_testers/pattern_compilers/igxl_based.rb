module OrigenTesters
  module PatternCompilers
    class IGXLBasedPatternCompiler < BasePatternCompiler
      def initialize(id, options = {})
        super

        # The following are pattern compiler options that are common between all IGXL platforms, these
        #   are added onto the base options.  Specifc IGXL platforms can add on additional options
        #   in their respective initialize methods.
        @user_options = {}.merge(@user_options)

        @job_options = {
          pinmap_workbook: dut.pinmap    # required: will default to $dut.pinmap
        }.merge(@job_options)

        # These are compiler options that are common to both the UltraFLEX and J750 compilers
        # Set all of these compiler options that don't have args to true/flase.  if true then send compiler '-opt'
        @compiler_options = {
          comments:              false,     # preserves comments in pattern binary
          cpp:                   false,     # runs C++ preprocessor on pattern file
          debug:                 false,     # generate intermediate file(s) to simplify debug ( application dependent )
          import_all_undefineds: false,     # automatically import all undefined symbols.  the key is mis-spelled but correct!
          suppress_log:          false,     # disables output to main log file
          template:              false,     # generate setup template
          timestamp:             false     # enable log timestamp
        }.merge(@compiler_options)

        # These are compiler options that are common to both the UltraFLEX and J750 compilers
        @compiler_options_with_args = {
          define:       nil,       # Define macro values to be passed to C-preprocessor
          digital_inst: nil,       # Name of digital instrument
          logfile:      nil,       # Messages go to <filename> instead of <infile> log
          opcode_mode:  nil,       # Patgen opcode mode, specific to digital instrument
          output:       nil,       # Name of output file
          pinmap_sheet: nil,       # Name of workbook containing pinmap
          # pinmap_workbook:     nil,       # Name of sheet in workbook which contains pinmap (moved to @job_options)
          setup:        nil       # path to setup file
        }.merge(@compiler_options_with_args)
      end

      def verify_pinmap_is_specified
        if @job_options[:pinmap_workbook].nil?
          # Check if the app has dut.pinmap defined
          if dut.pinmap && File.exist?(dut.pinmap)
            @job_options[:pinmap_workbook] = dut.pinmap
          else
            fail 'Pinmap is not defined!  Pass as an option or set $dut.pinmap.'
          end
        end
        @job_options[:pinmap_workbook] = convert_to_pathname(@job_options[:pinmap_workbook])
        fail 'Pinmap is not a file!' unless @job_options[:pinmap_workbook].file?
      end

      # Return the compiler instance pinmap
      def pinmap
        @job_options[:pinmap_workbook]
      end

      # Executes the compiler for each job in the queue
      def run(list = nil, options = {})
        # Check if there was a pattern list passed as an argument
        # If so, then compile the patterns inside it.
        # Otherwise compile the jobs in the queue
        if list.nil?
          if empty?
            empty_msg
            return
          end
          @jobs.each do |job|
            fail "Error: compiler #{job.id} not ready for pattern #{job.name}" unless job.ready?

            if job.location == :lsf
              Origen.app.lsf.submit(ATPC_SETUP + '; ' + job.cmd)
            else
              Origen.profile "Linux pattern compiler compiles pattern #{job.pattern}" do
                system job.cmd
              end
            end
          end
          if @job_options[:location] == :local
            if @job_options[:clean] == true
              puts 'Log file :clean option set to true, deleting log files'
              clean_output
            end
          end
          # Clear @jobs
          clear
        else
          list = convert_to_pathname(list)
          fail "Error: pattern list #{list} does not exist, exiting..." unless list.file?

          File.open(list, 'r') do |file|
            while (line = file.gets)
              current_job_options = @job_options.merge(@compiler_options_with_args)
              current_job_options.update_common(options)
              # puts "current job options is #{current_job_options}"
              compiler_opts = {}
              line.strip!
              pattern = line.match(/^(\S+)\s+(.*)/).captures[0]
              unless File.file? pattern
                puts "Warning: Pattern #{pattern} does not exist, skipping..."
                next
              end
              pattern = convert_to_pathname(pattern)
              line.match(/^\S+\s+(.*)/).captures[0].split(/\s+/).each do |e|
                opt, arg = e.split(':')
                opt.gsub!('-', '')
                if arg.nil?
                  compiler_opts[opt.to_sym] = true
                else
                  # Check for some specific options
                  case opt
                    when 'pinmap_workbook'
                      current_job_options[opt.to_sym] = Pathname.new(arg)
                    when 'output'
                      dot_pat = Pathname.new(arg)
                      current_job_options[:output_directory] = dot_pat.dirname
                    else
                      current_job_options[opt.to_sym] = arg
                  end
                end
              end
              @jobs << Job.new(pattern, current_job_options, compiler_opts)
              inspect_jobs
            end
          end
          run
          # Clear @jobs
          clear
        end
      end

      # Finds the patterns and creates a compiler job for each one found.
      # Handles singles files (.atp, .atp.gz, or .list) and directories (recursively or flat)
      def find_jobs(path = @path)
        fail 'Pattern path is set to nil, pass in a valid file (.atp or .atp.gz) or a valid directory' if path.nil?

        @path = Pathname.new(path)
        fail 'Pattern path does not exist, pass in a valid file (.atp or .atp.gz) or a valid directory' unless @path.exist?

        @path = @path.expand_path
        # Set the reference directory for pattern sub-dir mirroring
        set_reference_directory
        Origen.profile 'Linux pattern compiler finds patterns' do
          # Check if the path is a file or a directory
          if @path.directory?
            # Get all of the patterns inside this dir or inside this directory recursively
            process_directory(@path, @files, @user_options[:recursive])
          elsif @path.file? # Found a file so no searching is necessary
            process_file(@path, @files)
          else # Didn't find a directory or a file so user must want a search for this arg string * NOT SUPPORTED YET
            fail 'Error: Did not find a file or directory to compile, exiting...'
          end
        end

        Origen.profile 'Linux pattern compiler creates jobs' do
          @files.each do |f|
            rel_dir = Pathname.new("#{f.dirname.to_s[@user_options[:reference_directory].to_s.size..-1]}")
            if @job_options[:output_directory].nil?
              # job output dir not specified, create a unique (hash) based on path/compiler_name
              s = Digest::MD5.new
              s << @user_options[:reference_directory].to_s
              s << @id.to_s
              out = "#{@user_options[:reference_directory]}/job_#{@id}_#{s.to_s[0..6].upcase}#{rel_dir}"
              output_dir = Pathname.new(out)
            else
              output_dir = Pathname.new("#{@job_options[:output_directory]}#{rel_dir}")
            end
            unless output_dir.directory?
              puts "Output directory #{output_dir} for pattern #{f.basename} does not exist, creating it..."
              FileUtils.mkdir_p(output_dir)
            end
            current_job_options = @job_options.merge(@compiler_options_with_args)
            current_job_options[:output_directory] = output_dir
            @jobs << Job.new(f, current_job_options, @compiler_options)
            current_job_options = {}
          end
        end
        @files = []
        if empty?
          empty_msg
        else
          inspect_jobs
        end
      end

      # Output all of the jobs into a pattern list so it can be compiled later
      # Must be executed after the 'find_jobs' method and before the 'run' method
      # or @jobs will be empty
      def to_list(options = {})
        options = {
          name:             @id,
          output_directory: Dir.pwd,
          expand:           true,
          force:            false
        }.update_common(options)
        list = "#{options[:output_directory]}/#{options[:name]}.list"
        list = convert_to_pathname(list)
        if empty?
          empty_msg
          return
        end
        if list.file?
          if options[:force] == true
            puts "Pattern list file #{list} already exists, deleting it..."
            list.delete
          else
            fail "Pattern list file #{list} already exists, exiting..."
          end
        end
        File.open(list, 'w') do |patlist|
          @jobs.each do |job|
            if options[:expand] == true
              pinmap = job.pinmap_workbook
              dot_pat_name = "#{job.output_directory}/#{job.pattern.basename.to_s.split('.').first}.PAT"
              dot_atp_name = job.pattern
            else
              pinmap = job.pinmap_workbook.basename
              dot_pat_name = "#{job.pattern.basename.to_s.split('.').first}.PAT"
              dot_atp_name = job.pattern.basename
            end
            patlist.print("#{dot_atp_name} -pinmap_workbook:#{pinmap} -output:#{dot_pat_name}")
            job.compiler_options.each_key { |k| patlist.print(" -#{k}") }
            job.compiler_options_with_args.each_pair { |k, v| patlist.print(" -#{k}:#{v}") }
            patlist.puts('')
          end
        end
      end

      # alias_method :find, :find_jobs
      #
      # Output the compiler jobs in the queue to the console
      def inspect_jobs(index = nil)
        return empty_msg if empty?

        desc = []
        puts "\n"
        @jobs.each_with_index do |j, i|
          unless index.nil?
            next unless i == index
          end
          desc << '| Job: ' + "#{i + 1} ".rjust(8) + '|' + 'Pattern:'.rjust(18) + " #{j.pattern.basename}".ljust(120) + '|'
          desc << '|              |' + 'Compiler ID:'.rjust(18) + " #{j.id} ".ljust(120) + '|'
          desc << '|              |' + 'Pinmap:'.rjust(18) + " #{j.pinmap_workbook} ".ljust(120) + '|'
          desc << '|              |' + '.atp directory:'.rjust(18) + " #{j.pattern.dirname} ".ljust(120) + '|'
          desc << '|              |' + '.pat directory:'.rjust(18) + " #{j.output_directory} ".ljust(120) + '|'
          desc << '|              |' + 'LSF:'.rjust(18) + " #{j.location == :lsf ? true : false} ".ljust(120) + '|'
          desc << '|              |' + 'Delete log files:'.rjust(18) + " #{j.clean} ".ljust(120) + '|'
          desc << '|              |' + 'Verbose:'.rjust(18) + " #{j.verbose} ".ljust(120) + '|'
          fragment = '|              |' + 'Compiler args:'.rjust(18)
          overflow_fragment = '|              |' + ' '.rjust(18)
          compiler_args = []
          compiler_fragment = ''
          j.compiler_options.each_key do |k|
            if compiler_fragment.size + " -#{k}".size >= 120
              compiler_args << compiler_fragment
              compiler_fragment = nil
            end
            compiler_fragment += " -#{k}"
          end
          compiler_args << compiler_fragment unless compiler_fragment.nil?
          compiler_fragment = ''
          j.compiler_options_with_args.each_pair do |k, v|
            if compiler_fragment.size + " -#{k}:#{v}".size >= 120
              compiler_args << compiler_fragment
              compiler_fragment = nil
            end
            compiler_fragment += " -#{k}:#{v}"
          end
          compiler_args << compiler_fragment unless compiler_fragment.nil?
          if compiler_args.join.length <= 120
            desc << fragment + "#{compiler_args.join}".ljust(120) + '|'
          else
            # Need to cycle through compiler args and build a fragment <= 100 characters
            # and print it.  Keep going until the remaining args is <= 100 and print again
            char_cnt = 0
            line_cnt = 0
            args = []
            compiler_args = compiler_args.join.strip.split(/\s+/)
            until compiler_args.empty?
              args = compiler_args.select { |e| (char_cnt += e.length + 1) < 120 }
              # remove the args that fit on the first line
              compiler_args -= args
              if line_cnt == 0
                desc << fragment + " #{args.join(' ')}".ljust(120) + '|'
              else
                desc << overflow_fragment + " #{args.join(' ')}".ljust(120) + '|'
              end
              args = []
              line_cnt += 1
              char_cnt = 0
            end
          end
          desc << '-' * desc.first.size
        end
        puts desc.flatten.join("\n")
      end

      # For future checks on incorrect or incompatible arguments to compiler options
      def options_ok?
      end

      def ready?
        ready = true
        paths_contain_data = true
        ready &= paths_contain_data
        ready &= !@job_options[:output_directory].nil?
        ready &= !@user_options[:reference_directory].nil?
        ready &= !@path.nil?
        ready &= !@job_options[:pinmap_workbook].nil?
        ready &= @job_options[:output_directory].directory?
        ready &= @user_options[:reference_directory].directory?
        ready &= @path.exist?
        ready &= @job_options[:pinmap_workbook].file?
        ready &= [true, false].include?(@job_options[:clean])
        ready &= [:local, :lsf].include?(@job_options[:location])
        ready &= File.exist?(@job_options[:compiler])
        ready
      end

      def bad_options
        bad = []
        options = {
          output_directory:    @job_options[:output_directory],
          reference_directory: @user_options[:reference_directory],
          path:                @path,
          pinmap_workbook:     @job_options[:pinmap_workbook],
          clean:               @job_options[:clean],
          location:            @job_options[:location],
          compiler:            @job_options[:compiler]
        }
        options.each do |k, v|
          bad << k if v.nil?
          if v.is_a? String # compiler
            v = Pathname.new(v)
            bad << k unless v.file?
          elsif v.is_a? Symbol # clean
            bad << k unless [:local, :lsf].include? v
          elsif v.is_a? Pathname
            if k.match(/directory/)
              bad << k unless v.directory?
            elsif k == :path
              bad << k unless v.exist?
            else # pinmap
              bad << k unless v.file?
            end
          end
        end
        bad
      end
      alias_method :bad_opts, :bad_options
    end
  end
end
