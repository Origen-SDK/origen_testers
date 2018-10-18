require 'digest/md5'
module OrigenTesters
  module PatternCompilers
    class BasePatternCompiler
      require 'origen_testers/pattern_compilers/assembler'
      require 'origen_testers/pattern_compilers/job'

      # ID will allow users to set default configurations for the compiler for unique pattern types
      attr_accessor :id

      # Compiler commands array
      attr_accessor :jobs

      def initialize(id, options = {})
        unless Origen.site_config.origen_testers
          fail 'Adding a pattern compiler without site config specifying bin location not allowed'
        end

        @id = id.to_sym

        # The following are pattern compiler options that are common between all platforms, the specific platforms
        #   can add on additional options in their respective initialize methods.
        @user_options = {
          path:                nil,     # required: will be passed in or parsed from a .list file
          reference_directory: nil,     # optional: will be set to @path or Origen.app.config.pattern_output_directory
          target:              nil,     # optional: allows user to temporarily set target and run compilation
          recursive:           false,   # optional: controls whether to look for patterns in a directory recursively
        }

        @job_options = {
          id:               @id,        # required
          location:         :local,     # optional: controls whether the commands go to the LSF or run locally
          clean:            false,      # optional: controls whether compiler log files are deleted after compilation
          output_directory: nil,        # optional:
          verbose:          false,      # optional: controls whether the compiler output gets put to STDOUT
        }
        @compiler_options = {}
        @compiler_options_with_args = {}

        # Compiler jobs
        @jobs = []
        @files = []
      end

      # Return the id/name of the compiler instance
      def name
        @id
      end

      # Returns the number of jobs in the compiler
      def count
        @jobs.size
      end

      # Checks if the compiler queue is empty
      def empty?
        @jobs.empty?
      end

      # Allow users to search for a pattern in the job queue or default to return all jobs
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

      # Clear the job queue
      def clear
        @jobs = []
        @files = []
      end

      def platform
        if tester.nil?
          fail 'No tester instantiated, $tester is set to nil'
        else
          tester.class.to_s.downcase.split('::').last.to_sym
        end
      end

      # Check if the current tester is an Ultraflex
      def is_ultraflex?
        platform == :ultraflex ? true : false
      end

      # Check if the current tester is an J750
      def is_j750?
        platform == :j750 ? true : false
      end

      # Check if the current tester is an V93K
      def is_v93k?
        platform == :v93k ? true : false
      end

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

      private

      def update_common_options(options = {})
        @user_options.update_common(options)
        @job_options.update_common(options)
        @compiler_options.update_common(options)
        @compiler_options_with_args.update_common(options)
      end

      def clean_and_verify_options
        verify_exclusive_compiler_options
        clean_path_options
        set_reference_directory
        create_output_directory

        # Logfile is optional
        unless @compiler_options[:logfile].nil?
          @compiler_options[:logfile] = convert_to_pathname(@compiler_options[:logfile])
        end

        # Check if the LSF is setup in the application
        if Origen.app.config.lsf.project.nil? || Origen.app.config.lsf.project.empty?
          msg = 'LSF is not set at Origen.app.config.lsf.project, changing to local compilation'
          Origen.log.warn msg
          @job_options[:location] = :local
        end
      end

      # Check to make sure @compiler_options and @compiler_options_with_args do not have any keys in common
      def verify_exclusive_compiler_options
        if @compiler_options.intersect? @compiler_options_with_args
          fail_msg = 'Error: @compiler_options and @compiler_options_with_args share keys '
          fail_msg += "#{@compiler_options.intersections(@compiler_options_with_args)}.  "
          fail_msg += 'They should be mutually exclusive, exiting...'
          fail fail_msg
        end
      end

      def clean_path_options
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
      end

      def set_reference_directory
        if @user_options[:reference_directory].nil?
          # Nothing passed for reference directory so set it to @path or Origen.app.config.pattern_output_directory
          if @path
            if @path.directory?
              @user_options[:reference_directory] = @path
            else
              @user_options[:reference_directory] = @path.dirname
            end
          else
            # @path has not been specified, so set to Origen.app.config.pattern_output_directory (create if necessary)
            if Origen.app.config.pattern_output_directory.nil?
              fail "Something went wrong, can't create pattern compiler without output_directory"
            else
              @user_options[:reference_directory] = Pathname.new(Origen.app.config.pattern_output_directory)
              unless @user_options[:reference_directory].directory?
                FileUtils.mkdir_p(@user_options[:reference_directory])
              end
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
            fail "Path is set to #{@path} which is not a valid directory or file!"
          end
        end
      end

      def create_output_directory
        # if output directory given, create it now, otherwise it will be created on the fly later
        unless @job_options[:output_directory].nil?
          @job_options[:output_directory] = convert_to_pathname(@job_options[:output_directory])
          # output_directory can not exist, will create for user
          unless @job_options[:output_directory].directory?
            puts "Output directory #{@job_options[:output_directory]} does not exist, creating it..."
            FileUtils.mkdir_p(@job_options[:output_directory])
          end
        end
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
    end
  end
end
