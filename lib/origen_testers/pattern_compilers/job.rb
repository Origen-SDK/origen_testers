module Testers
  module PatternCompilers
    class Job
      # Pattern to be compiled, is Pathname class.  Will use full path
      attr_accessor :pattern

      # Type of pattern as designated by the LinuxPatternCompiler
      attr_accessor :id

      # Where the job is to be executed, either locally ('local') or on Linux Server Farm ('lsf')
      attr_accessor :location

      # Controls whether the compiler log files are kept: true/false
      attr_accessor :clean

      # Controls whether the compiler STDOUT is displayed
      attr_accessor :verbose

      # Output directory for the .PAT file
      attr_accessor :output_directory

      # Pinmap file
      attr_accessor :pinmap_workbook

      # Compiler options where only the opt has to be passed as '-opt'
      attr_accessor :compiler_options

      # Compiler options where an opt and an arg have to be passed '-opt:arg'
      attr_accessor :compiler_options_with_args

      # linux compiler full path
      attr_reader :compiler

      def initialize(pattern, options_with_args, options)
        @pattern = pattern
        @compiler = options_with_args.delete(:compiler)
        @id = options_with_args.delete(:id)
        @location = options_with_args.delete(:location)
        @clean = options_with_args.delete(:clean)
        @verbose = options_with_args.delete(:verbose)
        @output_directory = options_with_args.delete(:output_directory)
        @pinmap_workbook = options_with_args.delete(:pinmap_workbook)
        @compiler_options_with_args = options_with_args.delete_if { |k, v| v.nil? }  # Whatever's left has to be valid compiler options
        @compiler_options = options.delete_if { |k, v| v == false }
      end

      def name
        @pattern.basename
      end

      def cmd
        cmd = ''
        cmd = "#{@compiler} -pinmap_workbook:#{@pinmap_workbook} -output:#{@output_directory}/#{@pattern.basename.to_s.split('.').first}.PAT #{@pattern} "
        # add in any remaining compiler options
        compiler_options.each_key { |k| cmd += "-#{k} " }
        compiler_options_with_args.each_pair { |k, v| cmd += "-#{k}:#{v} " }
        if @verbose
          cmd += ';'
        else
          cmd += '2>&1 > /dev/null;'
        end
        # If the job is to be run on the LSF add in the clean .log and mv the files if necessary
        if @location == 'lsf'
          cmd += clean_lsf if @clean == true
        end
        cmd
      end

      def ready?
        ready = true
        ready && @output_directory.directory? &&
          @pattern.file? && @pinmap_workbook.file? &&
          [true, false].include?(@clean) &&
          [:local, :lsf].include?(@location)
      end

      private

      def orig_dir
        @pattern.dirname
      end

      # Generates the LSF commands to delete the pattern compiler log files
      def clean_lsf
        cmd = ''
        logfile = Pathname.new("#{@pattern.dirname}/#{@pattern.basename.to_s.split('.').first}.log")
        logfile.cleanpath
        logfile.cleanpath
        if @clean == true
          cmd += "rm #{logfile}; "
        end
        cmd
      end
    end
  end
end
