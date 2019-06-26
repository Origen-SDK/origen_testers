module OrigenTesters
  module PatternCompilers
    class V93KPatternCompiler < BasePatternCompiler
      require_relative 'v93k/multiport'
      include MultiportAPI
      require_relative 'v93k/digcap'
      include DigCapAPI

      attr_reader :avc_files, :max_avcfilename_size, :vec_per_frame

      TEMPLATE = "#{Origen.root!}/lib/origen_testers/pattern_compilers/templates/template.aiv.erb"

      # Linux compiler executable path
      def self.linux_compiler
        Origen.site_config.origen_testers[:v93k_linux_pattern_compiler]
      end

      # Windows compiler executable path - not available for V93K
      def self.windows_compiler
        nil
      end

      # Resolves to correct compiler (linux is only available)
      def self.compiler
        linux_compiler
      end

      def self.compiler_cmd
        Pathname.new(compiler).absolute? ? compiler : eval('"' + compiler + '"')
      end

      def self.compiler_options
        "#{compiler_cmd} -h"
      end

      def self.compiler_version
        "#{compiler_cmd} -V"
      end

      def initialize(id, options = {})
        super

        @user_options = {
          config_dir:    nil,        # Common directory where all configs can be stored
          pinconfig_dir: nil,        # Can override common config_dir if pinconfig stored elsewhere
          pinconfig:     nil,        # Can specify just file name (to use config_dir/pinconfig_dir), or give full path
          tmf_dir:       nil,        # Can override common config_dir if tmf stored elsewhere
          tmf:           nil,        # Can specify just file name (to use config_dir/tmf_dir), or give full path
          vbc_dir:       nil,        # Can override common config_dir if vbc stored elsewhere
          vbc:           nil,        # Can specify just file name (to use config_dir/vbc_dir), or give full path
          incl_dir:      nil,
          includes:      [],         # Array of files that will be copied into tmp job workspace before compilation
          tmp_dir:       nil,
          avc_dir:       nil,
          binl_dir:      nil,
          multiport:     nil,        # Optional hash for multiport settings: port_bursts, port_in_focus, prefix, postfix
          digcap:        nil,        # Optional hash for digcap settings: pins, vps, nrf, char
        }.merge(@user_options)

        @job_options = {
          tester:   :v93k,
          compiler: self.class.compiler,   # required
        }.merge(@job_options)

        @compiler_options = {

        }.merge(@compiler_options)

        @compiler_options_with_args = {
          aiv2b_opts:  nil
        }.merge(@compiler_options_with_args)

        @avc_files = []
        @vec_per_frame = {}

        update_common_options(options)      # Update common options with default (see BasePatternCompiler)
        verify_pinconfig_is_specified       # Verify pinconfig specified correctly - Smartest specific
        verify_tmf_is_specified             # Verify tmf specified correctly - Smartest specific
        clean_and_verify_options            # Standard cleaning and verifying (see BasePatternCompiler)
      end

      def pinconfig_file
        @pinconfig_file ||= build_file(:pinconfig)
      end

      def tmf_file
        @tmf_file ||= build_file(:tmf)
      end

      def vbc_file
        @vbc_file ||= build_file(:vbc)
      end

      def verify_pinconfig_is_specified
        fail 'Pinconfig file is not defined!  Pass as an option.' if pinconfig_file.nil?
        fail 'Pinconfig is not a file!' unless pinconfig_file.file?
      end

      def verify_tmf_is_specified
        fail 'Timing Map File (tmf) is not defined!  Pass as an option.' if tmf_file.nil?
        fail 'Timing Map File (tmf) is not a file!' unless tmf_file.file?
      end

      # Executes the compiler for each job in the queue
      def run(aiv = nil, options = {})
        aiv, options = nil, aiv if aiv.is_a? Hash

        fail "Error: the tester #{Origen.tester} is not an V93K tester, exiting..." unless is_v93k?

        msg = "Error: application #{Origen.app.name} is running on Windows, "
        msg += 'to run the pattern compiler you must be on a Linux machine'
        fail msg if Origen.running_on_windows?

        # Check if there was a pattern list passed as an argument
        # If so, then compile the patterns inside it.
        # Otherwise compile the jobs in the queue
        if aiv.nil?
          if empty?
            empty_msg
            return
          end
          @jobs.each do |job|
            unless options[:ignore_ready]
              fail "Error: compiler #{job.id} not ready for pattern #{job.name}" unless job.ready?
            end
            if job.location == :lsf
              # puts "#{self.class.aiv_setup} ; #{job.cmd}"
              # Origen.app.lsf.submit(self.class.aiv_setup + '; ' + job.cmd)
              Origen.app.lsf.submit(job.cmd)
            else
              Origen.profile "Linux pattern compiler compiles pattern #{job.pattern}" do
                Dir.chdir(job.output_directory) do
                  # puts "#{job.cmd}"
                  system job.cmd
                end
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
          # Assumes .aiv file and all workspace collateral has been built up
          aiv = convert_to_pathname(aiv)
          fail 'File does not exist!  Please specify existing aiv file.' unless aiv.file?
          current_job_options = @job_options.merge(@compiler_options_with_args)
          current_job_options = current_job_options.merge(extract_job_options_from_aiv(aiv))
          current_job_options = current_job_options.merge(options)
          current_job_options[:output_directory] = aiv.dirname

          @jobs << Job.new(Pathname.new(aiv), current_job_options, @compiler_options)
          inspect_jobs
          run(options)
        end
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
          desc << '| Job: ' + " #{i + 1} ".rjust(8) + '|' + 'Pattern/AIV:'.rjust(18) + " #{j.pattern.basename}".ljust(125) + '|'
          desc << '|              |' + 'Compiler ID:'.rjust(18) + " #{j.id} ".ljust(125) + '|'
          desc << '|              |' + 'AVC Files:'.rjust(18) + " #{j.count} ".ljust(125) + '|'
          desc << '|              |' + 'Output Directory:'.rjust(18) + " #{j.output_directory} ".ljust(125) + '|'
          desc << '|              |' + '.avc directory:'.rjust(18) + " #{j.avc_dir} ".ljust(125) + '|'
          desc << '|              |' + '.binl directory:'.rjust(18) + " #{j.binl_dir} ".ljust(125) + '|'
          desc << '|              |' + 'LSF:'.rjust(18) + " #{j.location == :lsf ? true : false} ".ljust(125) + '|'
          desc << '|              |' + 'Delete log files:'.rjust(18) + " #{j.clean} ".ljust(125) + '|'
          desc << '|              |' + 'Verbose:'.rjust(18) + " #{j.verbose} ".ljust(125) + '|'
          if j.aiv2b_opts && j.aiv2b_opts.is_a?(String)
            aiv2b_opts = j.aiv2b_opts.gsub('AI_V2B_OPTIONS ', '')
          else
            aiv2b_opts = render_aiv2b_options_line.gsub('AI_V2B_OPTIONS', '')
          end
          desc << '|              |' + 'AI_V2B Options:'.rjust(18) + " #{aiv2b_opts} ".ljust(125) + '|'
          desc << '-' * desc.first.size
        end
        puts desc.flatten.join("\n")
      end

      # Finds the patterns and creates a compiler job for each one found.
      # Handles singles files (.atp, .atp.gz, or .list) and directories (recursively or flat)
      def find_jobs(p = @path)
        # First-level verification: file/directory was given and exists
        msg = 'Pass in a valid file (.avc, .avc.gz, .list) or a valid directory'
        fail "Pattern path is set to nil! #{msg}" if p.nil?
        path = Pathname.new(p)
        fail "Pattern path does not exist! #{msg}" unless path.exist?
        path = path.expand_path

        # Set the reference directory for pattern sub-dir mirroring
        set_reference_directory

        # Collect file, list, or directory (recursively)
        Origen.profile 'Linux pattern compiler finds patterns' do
          if path.directory?
            # Get all of the patterns inside this dir or inside this directory recursively
            process_directory(path, @files, @user_options[:recursive])
          else
            # Found a file so no searching is necessary, process as single pattern or list
            process_file(path, @files)
          end
        end

        fail "Did not fild a valid file to compile! #{msg}" if @files.empty?

        Origen.profile 'Linux pattern compiler creates job' do
          # For V93K, only single AIV file is really sent to the compiler, but need list of all
          #   avc files that will be compiled using that aiv file, so keep a separate array.
          @max_avcfilename_size = 0
          @files.each do |f|
            @avc_files << Pathname.new(f).basename.sub_ext('').to_s
            @max_avcfilename_size = @avc_files[-1].size > @max_avcfilename_size ? @avc_files[-1].size : @max_avcfilename_size
          end

          rel_dir = Pathname.new("#{path.dirname.to_s[@user_options[:reference_directory].to_s.size..-1]}")

          # Resolve output directory
          if @job_options[:output_directory].nil?
            # job output dir not specified, create a unique (hash) based on path/compiler_name
            s = Digest::MD5.new
            s << @user_options[:reference_directory].to_s
            s << @id.to_s
            out = "#{@user_options[:reference_directory]}/job_#{@id}_#{s.to_s[0..6].upcase}#{rel_dir}"
            job_output_dir = Pathname.new(out)
          else
            job_output_dir = Pathname.new("#{@job_options[:output_directory]}#{rel_dir}")
          end

          # Create any necessary output directories before trying to compile
          unless job_output_dir.directory?
            puts "Output directory #{job_output_dir} does not exist, creating it..."
            FileUtils.mkdir_p(job_output_dir)
          end

          job_avc_dir = avc_dir.absolute? ? avc_dir : Pathname.new("#{job_output_dir}/#{avc_dir}").cleanpath
          unless job_avc_dir.directory?
            puts "AVC Output directory #{job_avc_dir} does not exist, creating it..."
            FileUtils.mkdir_p(job_avc_dir)
          end
          job_binl_dir = binl_dir.absolute? ? binl_dir : Pathname.new("#{job_output_dir}/#{binl_dir}").cleanpath
          unless job_binl_dir.directory?
            puts "BINL Output directory #{job_binl_dir} does not exist, creating it..."
            FileUtils.mkdir_p(job_binl_dir)
          end

          # Move AVC files into job space (through pre-processor)
          @files.each do |file|
            contents = File.open(file, 'rb') { |f| f.read }
            new_contents = preprocess_avc(contents)
            new_avc_file = Pathname.new("#{job_avc_dir}/#{Pathname.new(file).basename}").cleanpath
            File.open(new_avc_file, 'w') { |f| f.write(new_contents.force_encoding('UTF-8')) }
            avc_key = Pathname.new(file).basename.sub_ext('').to_s.to_sym
            @vec_per_frame[avc_key] = digcap? ? avc_digcap_vpf(new_contents) : 0
          end

          # Generate the AIV file using the template with all the pattern compiler parameters
          aiv_file = "#{job_output_dir}/#{path.basename.to_s.split('.')[0]}.aiv"
          Origen.log.info "Creating...  #{aiv_file}"
          contents = Origen.compile(self.class::TEMPLATE, scope: self, preserve_target: true)
          File.open(aiv_file, 'w') { |f| f.write(contents) }

          # Copy Timing Map File to local AIV workspace
          dest = Pathname.new("#{job_output_dir}/#{tmf_file.basename}").cleanpath
          FileUtils.cp tmf_file, dest

          # Copy VBC file to local AIV workspace (if specified)
          if vbc_file
            dest = Pathname.new("#{job_output_dir}/#{vbc_file.basename}").cleanpath
            FileUtils.cp vbc_file, dest
          end

          # Copy any extra files needed (includes)
          @user_options[:includes].each do |incl|
            src = build_file(:incl, incl)
            dest = Pathname.new("#{job_output_dir}/#{src.basename}").cleanpath
            FileUtils.cp src, dest
          end

          # Gather up job options
          current_job_options = @job_options.merge(@compiler_options_with_args)
          current_job_options[:output_directory] = job_output_dir
          current_job_options[:pinconfig] = pinconfig_file
          current_job_options[:tmf] = tmf_file
          current_job_options[:count] = @avc_files.count
          current_job_options[:avc_dir] = avc_dir
          current_job_options[:binl_dir] = binl_dir

          # Create new job
          @jobs << Job.new(Pathname.new(aiv_file), current_job_options, @compiler_options)
          current_job_options = {}
        end

        # Clear files and avc_files now that job has successfully been queued
        @files = []
        @avc_files = []
        @vec_per_frame = {}
        inspect_jobs
      end

      # Given the file contents, parse and calculate number of capture vectors
      def avc_digcap_vpf(contents)
        capture_vectors = 0
        contents.each_line do |line|
          if line[0] != "\#"     # skip any comment lines
            capture_vectors += 1 if /#{digcap.capture_string}/.match(line)
          end
        end
        capture_vectors
      end

      def avc_dir
        @avc_dir ||= begin
          if @user_options[:avc_dir]
            clean_path(@user_options[:avc_dir].to_s)
          else
            Pathname.new('./AVC')      # default value
          end
        end
      end

      def binl_dir
        @binl_dir ||= begin
          if @user_options[:binl_dir]
            clean_path(@user_options[:binl_dir].to_s)
          else
            Pathname.new('./BINL')     # default value
          end
        end
      end

      def tmp_dir
        @tmp_dir ||= begin
          if @user_options[:tmp_dir]
            clean_path(@user_options[:tmp_dir].to_s)
          else
            Pathname.new('./tmp')     # default value
          end
        end
      end

      # Given path string, return Pathname object with cleaned up path
      def clean_path(path_str)
        path = Pathname.new(path_str).cleanpath
        if path.absolute?
          return path
        else
          return Pathname.new("./#{path}")
        end
      end

      # Placeholder - TopLevel can monkey patch this method to do more
      #   sophisticated AVC modification prior to compilation
      def preprocess_avc(contents)
        new_contents = contents   # no manipulation done here
        new_contents
      end

      def render_aiv2b_options_line
        line = 'AI_V2B_OPTIONS'
        if @compiler_options_with_args[:aiv2b_opts]
          if @compiler_options_with_args[:aiv2b_opts].is_a? Array
            @compiler_options_with_args[:aiv2b_opts].each do |opt|
              line += " #{opt}"
            end
          elsif @compiler_options_with_args[:aiv2b_opts].is_a? String
            line += " #{@compiler_options[:aiv2b]}"
          else
            fail 'aiv2b options must be an array or string'
          end
        end
        line += " -c #{vbc_file.basename}" if vbc_file
        line
      end

      def render_aiv_patterns_header
        line = 'PATTERNS '
        line += 'name'.ljust(max_avcfilename_size + 2)
        line += 'port'.ljust(multiport.port_in_focus.size + 2) if multiport?
        line += 'tmf_file'
        line
      end

      def render_aiv_patterns_entry(pattern)
        line = '         '
        line += "#{pattern}".ljust(max_avcfilename_size + 2)
        line += "#{multiport.port_in_focus}".ljust(multiport.port_in_focus.size + 2) if multiport?
        line += "#{tmf_file.basename}"
        line
      end

      private

      def extract_job_options_from_aiv(file)
        options = {}
        contents = File.open(file, 'rb') { |f| f.read }
        count = 0
        counting = false
        contents.each_line do |line|
          if match = line.match(/^avc_dir\s*(\S*)/)
            options[:avc_dir] = match.captures[0]
          end
          if match = line.match(/^pinconfig_file\s*(\S*)/)
            options[:pinconfig] = Pathname.new(match.captures[0])
          end
          if match = line.match(/^single_binary_pattern_dir\s*(\S*)/)
            options[:binl_dir] = match.captures[0]
          end
          if match = line.match(/^AI_V2B_OPTIONS/)
            options[:aiv2b_opts] = match.captures[0]
          end
          if counting
            if line.match(/\w+/)
              count += 1
            else
              counting = false
            end
          end
          if match = line.match(/^PATTERNS/)
            counting = true
          end
        end
        options[:count] = count
        options
      end

      def build_file(type, fstr = nil)
        type_dir = "#{type}_dir".to_sym
        fstr ||= @user_options[type]
        if fstr.nil?
          nil
        else
          if Pathname.new(fstr).absolute?
            Pathname.new(fstr)
          elsif @user_options[type_dir]
            Pathname.new("#{@user_options[type_dir]}/#{fstr}").cleanpath
          elsif @user_options[:config_dir]
            Pathname.new("#{@user_options[:config_dir]}/#{fstr}").cleanpath
          else
            Pathname.new("#{Origen.root!}/#{fstr}").cleanpath
          end
        end
      end
    end
  end
end
