module OrigenTesters
  module PatternCompilers
    class UltraFlexPatternCompiler
      require 'pathname'
      require_relative 'assembler'
      require_relative 'job'

      # Linux compiler executable path
      LINUX_PATTERN_COMPILER = "#{Origen.root!}/bin/latest/bin/atpcompiler"
      # LINUX_PATTERN_COMPILER = "#{Origen.root!}/bin/latest/bin/atpcompiler"

      # Windows compiler executable path
      WINDOWS_PATTERN_COMPILER = "#{ENV['IGXLROOT']}/bin/apc.exe"

      # Linux compiler preamble
      ATPC_SETUP = "#{Origen.root!}/bin/latest/etc/atpcrc.csh"

      # ID will allow users to set default configurations for the compiler for unique pattern types
      attr_accessor :id

      # Compiler commands array
      attr_accessor :jobs

      def initialize(id, options = {})
        @id = id
        @id = @id.to_sym

        @user_options = {
          path:                nil,                # required: will be passed in or parsed from a .list file
          reference_directory: nil, # optional: will be set to @path or Origen.app.config.pattern_output_directory
          target:              nil,              # optional: allows user to temporarily set target and run compilation
          recursive:           false          # optional: controls whether to look for patterns in a directory recursively
        }
        @job_options = {
          compiler:         running_on_windows? ? WINDOWS_PATTERN_COMPILER : LINUX_PATTERN_COMPILER,   # required
          id:               @id,                      # required
          pinmap_workbook:  $dut.pinmap, # required: will default to $dut.pinmap
          location:         :local,             # optional: controls whether the commands go to the LSF or run locally
          clean:            false,                 # optional: controls whether compiler log files are deleted after compilation
          output_directory: nil,        # optional:
          verbose:          false                # optional: controls whether the compiler output gets put to STDOUT
        }
        @compiler_options = { # Set all of these compiler options that don't have args to true/flase.  if true then send compiler '-opt'
          import_all_undefineds: false, # automatically import all undefined symbols.  the key is mis-spelled but correct!
          cpp:                   false,                   # runs C++ preprocessor on pattern file
          comments:              false,              # saves comments in binary file for tools visibility.  pass '-comments' if set to true
          # pass nothing if set to false
          nocompress:            false,            # do not compress pattern data blocks
          suppress_log:          false,          # disables output to main log file
          multiinst:             false,             # indicates more than one instrument is connected to a single pin
          lock:                  false,                  # prevents pattern from being reverse compiled or opened in PatternTool
          stdin:                 false,                 # Compile data from standard input. Do not use -cpp or specify any pattern file(s) when using this option.
          debug:                 false,                 # generate intermediate file(s) to simplify debug ( application dependent )
          template:              false,              # generate setup template
          timestamp:             false,             # enable log timestamp
        }
        @compiler_options_with_args = {
          output:              nil,                # Output filename, compiler defaults to <pattern name>.PAT
          pinmap_sheet:        nil,          # <sheetname>
          digital_inst:        nil,          # 'HSD4G', 'HSDM', or 'HSDMQ'
          opcode_mode:         nil,           # HSDM mode: 'single' | 'dual'. HSDMQ mode: 'single' | 'dual' | 'quad'
          pat_version:         nil,           # version of pattern file to compile
          scan_type:           nil,             # type of scan data
          max_errors:          nil,            # <n>, defaults to 200 on compiler side, valu eof 0 will never abort compilation
          logfile:             nil,               # <filename>, directs any compiler messages to <filename>.  will default to output directory if nil
          define:              nil,                # defines values of macros passed to C++ preprocessor.
          # can only be defined once per pattern with space delimited list
          includes:            nil,              # include paths to be passed to C- preprocessor.
          post_processor:      nil,        # <pathname> customer's post-process executable.
          # need to pass 'post-processor' to compiler
          post_processor_args: nil,   # <args> customer's post-process executable arguments
          # need to pass 'post-processor_args' to compiler
          cdl_cache:           nil,             # 'yes' | 'no', turns on/off CDL caching, default on compiler side is 'yes'
          init_pattern:        nil,          # <pattern>, uses the specified pattern module/file/set as an init patterns
          check_set_msb:       nil,         # 'yes' | 'no', turns on/off check the 'set' or 'set_infinite' opcode
          # is preceded by a 'set_msb' or 'set_msb_infinite' opcode. compiler default is 'yes'
          time_domain:         nil,           # <time domain>, specifies time domain for pins in patterns
          allow_mto_dash:      nil,        # Turn on/off support for channel data runtime repeat,i.e. vector dash in MTO patterns. Default value is "no".
          check_vm_min_size:   nil,     # Turns on/off the check on minimum size of a VM pattern. Default value is "yes".
          check_vm_mod_size:   nil,     # Turns on/off the check on a VM pattern module size. Default value is "yes".
          check_oob_size:      nil,        # Turns on/off the check on size of OOB regions. Yes means size must be modulo 10. Default value is "no".
          allow_mixed_1x2x:    nil,      # Turns on/off the support of mixed 1x/2x pin groups. Default value is "no".
          allow_differential:  nil,    # Turns on/off support for differential pins. Default value is "yes".
          allow_scan_in_srm:   nil,     # Allow/disallow scan vectors in SRM pattern modules. Default value is "no".
          vm_block_size:       nil,         # Specifies uncompressed size in bytes of a pattern data block
          setup:               nil,                 # path to setup file
        }

        @user_options.update_common(options)
        @job_options.update_common(options)
        @compiler_options.update_common(options)
        @compiler_options_with_args.update_common(options)

        # Check to make sure @compiler_options and @compiler_options_with_args do not have any keys in common
        fail "Error: @compiler_options and @compiler_options_with_args share keys #{@compiler_options.intersections(@compiler_options_with_args)}.  They should be mutually exclusive, exiting..." if @compiler_options.intersect? @compiler_options_with_args

        # Convert any path related options to Pathname object and expand the path
        unless @user_options[:path].nil?
          if @user_options[:path].is_a? Pathname
            @path = @user_options[:path]
          else
            @path = Pathname.new(@user_options[:path])
          end
          @path = @path.expand_path
          # path is set but output_directory is not so set output_directory to path
          @job_options[:output_directory] = @path if @job_options[:output_directory].nil?
        end

        set_reference_directory

        if @job_options[:output_directory].nil?
          fail 'Output directory is not set!'
        else
          @job_options[:output_directory] = convert_to_pathname(@job_options[:output_directory])
          # output_directory can not exist, will create for user
          unless @job_options[:output_directory].directory?
            puts "Output directory #{@job_options[:output_directory]} does not exist, creating it..."
            FileUtils.mkdir_p(@job_options[:output_directory])
          end
        end

        # Pinmap is required
        if @job_options[:pinmap_workbook].nil?
          # Check if the app has $dut.pinmap defined
          if File.exist? $dut.pinmap
            @job_options[:pinmap_workbook] = $dut.pinmap
          else
            fail 'Pinmap is not defined!  Pass as an option or set $dut.pinmap.'
          end
        end
        @job_options[:pinmap_workbook] = convert_to_pathname(@job_options[:pinmap_workbook])
        fail 'Pinmap is not a file' unless @job_options[:pinmap_workbook].file?

        # Logfile is optional
        unless @compiler_options[:logfile].nil?
          @compiler_options[:logfile] = convert_to_pathname(@compiler_options[:logfile])
          fail 'Pinmap is not a file' unless @job_options[:pinmap_workbook].file?
        end

        # Check if the LSF is setup in the application
        if Origen.app.config.lsf.project.nil? || Origen.app.config.lsf.project.empty?
          puts 'LSF is not set at Origen.app.config.lsf.project, changing to local compilation'
          @job_options[:location] = :local
        end

        # Compiler jobs
        @jobs = []

        # .atp/.atp.gz files found
        @files = []
      end

      # Return the id/name of the compiler instance
      def name
        @id
      end

      # Return the compiler instance pinmap
      def pinmap
        @job_options[:pinmap_workbook]
      end

      # Allow users to search for a pattern in the job queue or default
      # to return all jobs
      def jobs(search = nil)
        found = false
        if search.nil?
          inspect_jobs
          found = true
        elsif search.is_a? String
          @jobs.each_with_index do |job, index|
            if job.pattern.to_s.match(search)
              inspect_jobs(index)
              found = true
            else
              puts "No match found for #{search}"
            end
          end
        elsif search.is_a? Regexp
          @jobs.each_with_index do |job, index|
            if search.match(job.pattern.to_s)
              inspect_jobs(index)
              found = true
            else
              puts "No match found for #{search}"
            end
          end
        elsif search.is_a? Integer
          if @jobs[search].nil?
            puts "The compiler queue does not contain a job at index #{search}"
          else
            inspect_jobs(search)
            found = true
          end
        else
          fail 'Search argument must be of type String, Regexp, or Integer'
        end
        found
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
            # Check if the recursive arg was passed
            if @user_options[:recursive] == true
              process_directory(@path, @files, true)
            else # Just grab the files found inside this directory
              process_directory(@path, @files, false)
            end
          elsif @path.file? # Found a file so no searching is necessary
            process_file(@path, @files)
          else # Didn't find a directory or a file so user must want a search for this arg string * NOT SUPPORTED YET
            fail 'Error: Did not find a file or directory to compile, exiting...'
          end
        end

        Origen.profile 'Linux pattern compiler creates jobs' do
          @files.each do |f|
            rel_dir = Pathname.new("#{f.dirname.to_s[@user_options[:reference_directory].to_s.size..-1]}")
            output_dir = Pathname.new("#{@job_options[:output_directory]}#{rel_dir}")
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
      alias_method :find, :find_jobs

      # Executes the compiler for each job in the queue
      def run(list = nil, options = {})
        fail "Error: the tester #{Origen.tester} is not an Ultrflex tester,exiting..." unless is_ultraflex?
        fail "Error: application #{Origen.app.name} is running on Windows, to run the pattern compiler you must be on a Linux machine" if running_on_windows?

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

      # Clear the job queue
      def clear
        @jobs = []
        @files = []
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

      # For future checks on incorrect or incompatible arguments to compiler options
      def options_ok?
      end

      def ready?
        ready = true
        paths_contain_data = true
        # check for nil
        ready = paths_contain_data && !@job_options[:output_directory].nil? &&
                !@user_options[:reference_directory].nil? &&
                !@path.nil? &&
                !@job_options[:pinmap_workbook].nil?
        ready && @job_options[:output_directory].directory? &&
          @user_options[:reference_directory].directory? &&
          @path.exist? &&
          @job_options[:pinmap_workbook].file? &&
          [true, false].include?(@job_options[:clean]) &&
          [:local, :lsf].include?(@job_options[:location]) &&
          File.exist?(@job_options[:compiler])
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

      # Output the compiler options to the console
      def inspect_options(verbose = nil)
        desc = []
        # Find the longest option argument string
        my_job_options = @job_options
        my_job_options.delete(:compiler)
        all_arguments = @user_options.values + my_job_options.values + @compiler_options.values + @compiler_options_with_args.values
        min_argument_padding = 'Argument'.length + 2
        argument_padding = all_arguments.max_by { |e| e.to_s.length }.to_s.length + 3
        argument_padding = min_argument_padding if argument_padding < min_argument_padding
        puts "\n"
        header = '| Option              ' + '| Argument'.ljust(argument_padding) + '| Required |'
        desc << header
        desc << '-' * header.length
        [@user_options, my_job_options, @compiler_options, @compiler_options_with_args].each do |opt|
          opt.each_pair do |k, v|
            if k.match(/pinmap_workbook|path|id|directory|clean|location|recursive/i)
              req = 'true '
            else
              next if v.nil? || v == false
              req = 'false'
            end
            desc << "| #{k}".ljust(22) + "| #{v}".ljust(argument_padding) + "| #{req}    |"
          end
        end
        puts desc
      end

      # Output the compiler jobs in the queue to the console
      def inspect_jobs(index = nil)
        return empty_msg if empty?
        desc = []
        puts "\n"
        @jobs.each_with_index do |j, i|
          unless index.nil?
            next unless i == index
          end
          desc << '| Job: ' + "#{i + 1} ".rjust(8) + '|' + 'Pattern:'.rjust(18) + " #{j.pattern.basename}".ljust(100) + '|'
          desc << '|              |' + 'Compiler ID:'.rjust(18) + " #{j.id}".ljust(100) + '|'
          desc << '|              |' + 'Pinmap:'.rjust(18) + " #{j.pinmap_workbook}".ljust(100) + '|'
          desc << '|              |' + '.atp directory:'.rjust(18) + " #{j.pattern.dirname}".ljust(100) + '|'
          desc << '|              |' + '.pat directory:'.rjust(18) + " #{j.output_directory}".ljust(100) + '|'
          desc << '|              |' + 'LSF:'.rjust(18) + " #{j.location == :lsf ? true : false}".ljust(100) + '|'
          desc << '|              |' + 'Delete log files:'.rjust(18) + " #{j.clean}".ljust(100) + '|'
          desc << '|              |' + 'Verbose:'.rjust(18) + " #{j.verbose}".ljust(100) + '|'
          fragment = '|              |' + 'Compiler args:'.rjust(18)
          overflow_fragment = '|              |' + ' '.rjust(18)
          compiler_args = []
          compiler_fragment = ''
          j.compiler_options.each_key do |k|
            if compiler_fragment.size + " -#{k}".size >= 100
              compiler_args << compiler_fragment
              compiler_fragment = nil
            end
            compiler_fragment += " -#{k}"
          end
          compiler_args << compiler_fragment unless compiler_fragment.nil?
          compiler_fragment = ''
          j.compiler_options_with_args.each_pair do |k, v|
            if compiler_fragment.size + " -#{k}:#{v}".size >= 100
              compiler_args << compiler_fragment
              compiler_fragment = nil
            end
            compiler_fragment += " -#{k}:#{v}"
          end
          compiler_args << compiler_fragment unless compiler_fragment.nil?
          if compiler_args.join.length <= 100
            desc << fragment + "#{compiler_args.join}".ljust(100) + '|'
          else
            # Need to cycle through compiler args and build a fragment <= 100 characters
            # and print it.  Keep going until the remaining args is <= 100 and print again
            char_cnt = 0
            line_cnt = 0
            args = []
            compiler_args = compiler_args.join.strip.split(/\s+/)
            until compiler_args.empty?
              args = compiler_args.select { |e| (char_cnt += e.length + 1) < 100 }
              # remove the args that fit on the first line
              compiler_args -= args
              if line_cnt == 0
                desc << fragment + " #{args.join(' ')}".ljust(100) + '|'
              else
                desc << overflow_fragment + " #{args.join(' ')}".ljust(100) + '|'
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

      # Returns the number of jobs in the compiler
      def count
        @jobs.size
      end

      # Checks if the compiler queue is empty
      def empty?
        @jobs.empty?
      end

      private

      def running_on_windows?
        RUBY_PLATFORM == 'i386-mingw32'
      end

      def empty_msg
        puts "No compiler jobs created, check the compiler options\n" if self.empty?
      end

      def convert_to_pathname(opt)
        if opt.is_a? String
          opt = Pathname.new(opt)
          opt = opt.expand_path
        elsif opt.is_a? Pathname
          opt = opt.expand_path
        else
          fail "Option #{opt} is not a String, cannot convert to Pathname"
        end
        opt
      end

      def set_reference_directory
        if @user_options[:reference_directory].nil?
          # Nothing passed for reference directory so set it to Origen.app.config.pattern_output_directory if valid
          if File.directory? Origen.app.config.pattern_output_directory
            @user_options[:reference_directory] = Pathname.new(Origen.app.config.pattern_output_directory)
          elsif @path
            if @path.directory?
              @user_options[:reference_directory] = @path
            else
              @user_options[:reference_directory] = @path.dirname
            end
          end
        elsif File.directory?(@user_options[:reference_directory])
          @user_options[:reference_directory] = Pathname.new(@user_options[:reference_directory])
        else
          debug 'Reference directory not set, creating it...'
          @user_options[:reference_directory] = Pathname.new(@user_options[:reference_directory])
          FileUtils.mkdir_p(@user_options[:reference_directory])
        end
        @user_options[:reference_directory] = @user_options[:reference_directory].expand_path
        # reference_directory must be a subset of @path. if it is not then set to @path if @path exists
        unless @path.nil?
          if @path.directory?
            @user_options[:reference_directory] = @path unless @path.to_s.include? @user_options[:reference_directory].to_s
          elsif @path.file?
            @user_options[:reference_directory] = @path.dirname
          else
            debug "Path is set to #{@path} which is not a valid directory or file!"
          end
        end
      end

      # Check if the current tester is an Ultraflex
      def is_ultraflex?
        platform == :ultraflex ? true : false
      end

      def platform
        if $tester.nil?
          fail 'No tester instantiated, $tester is set to nil'
        else
          $tester.class.to_s.downcase.split('::').last.to_sym
        end
      end
    end
  end
end
