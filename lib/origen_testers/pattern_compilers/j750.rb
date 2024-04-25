module OrigenTesters
  module PatternCompilers
    class J750PatternCompiler < IGXLBasedPatternCompiler
      # Linux compiler executable path
      def self.linux_compiler
        Origen.site_config.origen_testers[:j750_linux_pattern_compiler]
      end

      # Windows compiler executable path
      def self.windows_compiler
        Origen.site_config.origen_testers[:j750_windows_pattern_compiler]
      end

      # Pre-compile environment setup if necessary
      def self.atpc_setup
        Origen.site_config.origen_testers[:j750_atpc_setup]
      end

      # Resolves to correct compiler based on operating system
      def self.compiler
        Origen.running_on_windows? ? windows_compiler : linux_compiler
      end

      def self.compiler_cmd
        Pathname.new(compiler).absolute? ? compiler : eval('"' + compiler + '"')
      end

      def self.compiler_options
        "#{compiler_cmd} -help"
      end

      def self.compiler_version
        "#{compiler_cmd} -version"
      end

      def initialize(id, options = {})
        super

        @user_options = {}.merge(@user_options)

        @job_options = {
          tester:   :j750,
          compiler: self.class.compiler   # required
        }.merge(@job_options)

        # These are compiler options that are specific to J750 compiler (builds on options from IGXL-Based)
        # Set all of these compiler options that don't have args to true/flase.  if true then send compiler '-opt'
        @compiler_options = {
          compress:      false,     # Compress the compiled output file.
          extended:      false,     # Compiles the pattern for extended mode.
          scan_parallel: false,     # Expands scan vectors into parallel SVM/LVM vectors.
          svm_only:      false,     # Compile all vectors in the file for SVM.
          svm_subr_only: false     # Only SVM subroutines in file being used.
        }.merge(@compiler_options)

        # These are compiler options that are specific to J750 compiler (builds on options from IGXL-Based)
        @compiler_options_with_args = {
          i:          nil,          # Includes paths to be passed to C++ preprocessor.
          lvm_size:   nil,          # Number of LVM vectors to allow in a single pattern.
          max_errors: nil,          # Number of errors that will cause compilation of the pattern file to be aborted.
          min_period: nil          # Minimum period, in seconds, that will be used during a pattern burst.
        }.merge(@compiler_options_with_args)

        update_common_options(options)      # Update common options with default (see BasePatternCompiler)
        verify_pinmap_is_specified          # verify pinmap specified correctly - IGXL specific
        clean_and_verify_options            # Standard cleaning and verifying (see BasePatternCompiler)
      end

      # Executes the compiler for each job in the queue
      def run(list = nil, options = {})
        fail "Error: the tester #{Origen.tester} is not an J750 tester,exiting..." unless is_j750?

        msg = "Error: application #{Origen.app.name} is running on Windows, "
        msg += 'to run the pattern compiler you must be on a Linux machine'
        fail msg if Origen.running_on_windows?

        super
      end
    end
  end
end
