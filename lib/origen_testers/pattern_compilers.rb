module OrigenTesters
  module PatternCompilers
    require 'origen_testers/pattern_compilers/base'
    require 'origen_testers/pattern_compilers/igxl_based'
    require 'origen_testers/pattern_compilers/ultraflex'
    require 'origen_testers/pattern_compilers/j750'
    require 'origen_testers/pattern_compilers/v93k'

    PLATFORMS = {
      ultraflex: 'UltraFLEX',
      j750:      'J750',
      v93k:      'V93K'
    }

    # Hash wrapper for compiler instances, defaults to display currently enabled tester platform.
    # If no tester is set then user must supply a valid tester platform argument
    # User can also supply alternate tester platform (i.e. not the current tester target)
    #  pattern_compilers()                    => hash of compilers for current tester platform
    #  pattern_compilers(id1)                 => inspect options of compiler 'id1' for current tester platfrom
    #  pattern_compiler(platform: :v93k)      => hash of compilers for specified tester platfrom (v93k)
    #  pattern_compiler(id2, platform: :v93k) => inspect options of compiler 'id2' for specified tester platfrom (v93k)
    def pattern_compilers(id = nil, options = {})
      id, options = nil, id if id.is_a? Hash
      plat = options[:platform] || platform     # use platform option or current tester platform

      # Build up empty hash structure for all supported plaforms
      @pattern_compilers ||= begin
        hash = {}
        PLATFORMS.keys.each { |p| hash[p] = {} }
        hash
      end

      @default_pattern_compiler ||= begin
        hash = {}
        PLATFORMS.keys.each { |p| hash[p] = nil }
        hash
      end

      if id.nil?
        @pattern_compilers[plat]
      else
        @pattern_compilers[plat][id].inspect_options
      end
    end
    # alias_method :compilers, :pattern_compilers     # DEPRECATING

    # Add a compiler for a particular tester platform and pattern type
    def add_pattern_compiler(id, plat, options = {})
      pattern_compilers
      id = id.to_sym
      plat = plat.to_sym
      options[:location] = options[:location].to_sym unless options[:location].nil?

      verify_unique_platform_id(id, plat)    # do not allow duplicate ids for a given platform
      @pattern_compilers[plat][id] = platform_compiler(plat).new(id, options)

      default = options[:default] || false
      @default_pattern_compiler[plat] = id if default
    end
    # alias_method :add_compiler, :add_pattern_compiler     # DEPRECATING

    # Get the default pattern compiler for the current of speficied platform
    def default_pattern_compiler(p = platform)
      @default_pattern_compiler[p.to_sym]
    end

    # Set a (already created) pattern compiler as the default for current or specified platform
    def set_default_pattern_compiler(id, p = platform)
      @default_pattern_compiler[p.to_sym] = id
    end

    # All platforms that have supported pattern compilers (returns Array)
    def pattern_compiler_platforms
      PLATFORMS.keys.sort
    end
    # alias_method :compiler_platforms, :pattern_compiler_platforms     # DEPRECATING

    # Delete all pattern compiler instances for a given platform.  If no
    #   argument default to current platform
    def delete_pattern_compilers(p = platform)
      @pattern_compilers[p].delete_if { |k, v| true }
    end
    # alias_method :delete_compilers, :delete_pattern_compilers     # DEPRECATING

    # Delete a pattern compiler instance.
    def delete_pattern_compiler(id, p = platform)
      @pattern_compilers[p].delete(id)
    end
    # alias_method :delete_compiler, :delete_pattern_compiler     # DEPRECATING

    # Check compiler instance name is unique for given platform
    def verify_unique_platform_id(id, platform, options = {})
      if @pattern_compilers[platform].keys.include? id
        fail_msg = "Compiler ID #{id} for platform #{platform} already exists! "
        fail_msg += 'Pick another name, delete the compiler, or clear all compilers'
        fail fail_msg
      end
    end

    # Returns an array of the pattern compiler instance ids
    # for the currently selected tester platform.
    def pattern_compiler_instances(p = platform)
      # Check if nil which means no tester is defined so ask user to supply it
      if p.nil?
        fail "No tester platform defined, supply one of the following as an argument: #{PLATFORMS.keys.sort.join(', ')}"
      end

      p = p.to_sym
      @pattern_compilers[p].keys
    end
    # alias_method :compiler_instances, :pattern_compiler_instances       # DEPRECATING

    # Return the Compiler Class of the current or specified platform
    def platform_compiler(p = platform)
      if pattern_compiler_supported?(p)
        "OrigenTesters::PatternCompilers::#{PLATFORMS[p]}PatternCompiler".constantize
      else
        fail "Platform #{platform} is not valid, please choose from #{PLATFORMS.keys.sort.join(', ')}"
      end
    end

    # Execute the compiler with 'help' switch
    def pattern_compiler_options(p = platform)
      system("#{platform_compiler(p).compiler_options}")
    end
    # alias_method :compiler_options, :pattern_compiler_options           # DEPRECATING

    # Execute the compiler with 'version' swtich
    def pattern_compiler_version(p = platform)
      system("#{platform_compiler(p).compiler_version}")
    end
    # alias_method :compiler_version, :pattern_compiler_version           # DEPRECATING

    # Check if the current tester is supported
    def pattern_compiler_supported?(p = platform)
      PLATFORMS.keys.include?(p) ? true : false
    end
    # alias_method :compiler_supported?, :pattern_compiler_supported?     # DEPRECATING

    private

    # # Check if the current tester is an Ultraflex
    # def is_ultraflex?
    #   platform == :ultraflex ? true : false
    # end

    # # Check if the current tester is an Ultraflex
    # def is_j750?
    #   platform == :j750 ? true : false
    # end

    # # Check if the current tester is an Ultraflex
    # def is_v93k?
    #   platform == :v93k ? true : false
    # end

    # Return the current tester target
    def platform
      if tester.nil?
        fail 'No tester instantiated, $tester is set to nil'
      else
        tester.class.to_s.downcase.split('::').last.to_sym
      end
    end

    # # Check if a target has been set
    # def target_enabled?
    #   Origen.target.name.nil? ? true : false
    # end
  end
end
