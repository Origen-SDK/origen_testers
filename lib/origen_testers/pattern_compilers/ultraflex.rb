module OrigenTesters
  module PatternCompilers
    class UltraFLEXPatternCompiler < IGXLBasedPatternCompiler
      # Linux compiler executable path
      def self.linux_compiler
        Origen.site_config.origen_testers[:uflex_linux_pattern_compiler]
      end

      # Windows compiler executable path
      def self.windows_compiler
        Origen.site_config.origen_testers[:uflex_windows_pattern_compiler]
      end

      # Pre-compile environment setup if necessary
      def self.atpc_setup
        Origen.site_config.origen_testers[:uflex_atpc_setup]
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
          tester:   :ultraflex,
          compiler: self.class.compiler  # required
        }.merge(@job_options)

        # These are compiler options that are specific to UltraFLEX (builds on options from IGXL-Based)
        # Set all of these compiler options that don't have args to true/flase.  if true then send compiler '-opt'
        @compiler_options = {
          lock:       false,              # prevents pattern from being reverse compiled or opened in PatternTool
          multiinst:  false,              # indicates more than one instrument is connected to a single pin
          nocompress: false,              # do not compress pattern data blocks
          stdin:      false              # Compile data from standard input. Do not use -cpp or specify any pattern file(s) when using this option.
        }.merge(@compiler_options)

        # These are compiler options that are specific to UltraFLEX (builds on options from IGXL-Based)
        @compiler_options_with_args = {
          pat_version:         nil,       # version of pattern file to compile
          scan_type:           nil,       # type of scan data
          includes:            nil,       # include paths to be passed to C- preprocessor.
          post_processor:      nil,       # <pathname> customer's post-process executable.
          post_processor_args: nil,       # <args> customer's post-process executable arguments
          cdl_cache:           nil,       # 'yes' | 'no', turns on/off CDL caching, default on compiler side is 'yes'
          init_pattern:        nil,       # <pattern>, uses the specified pattern module/file/set as an init patterns
          check_set_msb:       nil,       # 'yes' | 'no', turns on/off check the 'set' or 'set_infinite' opcode
          time_domain:         nil,       # <time domain>, specifies time domain for pins in patterns
          allow_mto_dash:      nil,       # Turn on/off support for channel data runtime repeat,i.e. vector dash in MTO patterns. Default value is "no".
          check_vm_min_size:   nil,       # Turns on/off the check on minimum size of a VM pattern. Default value is "yes".
          check_vm_mod_size:   nil,       # Turns on/off the check on a VM pattern module size. Default value is "yes".
          check_oob_size:      nil,       # Turns on/off the check on size of OOB regions. Yes means size must be modulo 10. Default value is "no".
          allow_mixed_1x2x:    nil,       # Turns on/off the support of mixed 1x/2x pin groups. Default value is "no".
          allow_differential:  nil,       # Turns on/off support for differential pins. Default value is "yes".
          allow_scan_in_srm:   nil,       # Allow/disallow scan vectors in SRM pattern modules. Default value is "no".
          vm_block_size:       nil       # Specifies uncompressed size in bytes of a pattern data block
        }.merge(@compiler_options_with_args)

        update_common_options(options)    # Update common options with default (see BasePatternCompiler)
        verify_pinmap_is_specified        # verify pinmap specified correctly - IGXL specific
        clean_and_verify_options          # Standard cleaning and verifying (see BasePatternCompiler)
      end

      # Executes the compiler for each job in the queue
      def run(list = nil, options = {})
        fail "Error: the tester #{Origen.tester} is not an Ultrflex tester,exiting..." unless is_ultraflex?

        msg = "Error: application #{Origen.app.name} is running on Windows, "
        msg += 'to run the pattern compiler you must be on a Linux machine'
        fail msg if Origen.running_on_windows?

        super
      end
    end
  end
end
