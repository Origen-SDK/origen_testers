module Testers
  module PatternCompilers
    require 'pathname'
    require_relative 'pattern_compilers/ultraflex_pattern_compiler'

    PLATFORMS = [:ultraflex]

    # Linux compiler executable path
    LINUX_PATTERN_COMPILER = "#{Origen.root!}/bin/latest/bin/atpcompiler"

    # Windows compiler executable path
    WINDOWS_PATTERN_COMPILER = "#{ENV['IGXLROOT']}/bin/apc.exe"

    # Hash wrapper for compiler instances, defaults to display currently enabled
    # tester platform.  If none is set then user must supply a valid tester platform argument
    def pattern_compilers(id = nil)
      @pattern_compilers ||= begin
        hash = {}
        PLATFORMS.each { |platform| hash[platform] = {} }
        hash
      end
      if id.nil?
        @pattern_compilers[platform]
      else
        @pattern_compilers[platform][id].inspect_options
      end
    end
    alias_method :compilers, :pattern_compilers

    def pattern_compiler_platforms
      PLATFORMS
    end
    alias_method :compiler_platforms, :pattern_compiler_platforms

    # Delete pattern compiler instances.  If no argument default to current platform
    def delete_pattern_compilers(p = platform)
      @pattern_compilers[p].delete_if { |k, v| true }
    end
    alias_method :delete_compilers, :delete_pattern_compilers

    # Delete a pattern compiler instance.
    def delete_pattern_compiler(id)
      @pattern_compilers[platform].delete(id)
    end
    alias_method :delete_compiler, :delete_pattern_compiler

    # Add a compiler for a particular tester platform and pattern type
    def add_pattern_compiler(id, platform, options = {})
      pattern_compilers
      id = id.to_sym
      platform = platform.to_sym
      options[:location] = options[:location].to_sym unless options[:location].nil?
      case platform
      when :ultraflex
        fail "Compiler ID #{id} for platform #{platform} already exists!  Pick another name, delete the compiler, or clear all compilers" if @pattern_compilers[platform].keys.include? id
        @pattern_compilers[platform][id] = UltraFlexPatternCompiler.new(id, options)
      else
        fail "Platform #{platform} is not valid, please choose from #{PLATFORMS.join(', ')}"
      end
    end
    alias_method :add_compiler, :add_pattern_compiler

    # Returns an array of the pattern compiler instance ids
    # for the currently selected tester platform.
    def pattern_compiler_instances(p = platform)
      # Check if nil which means no tester is defined so ask user to supply it
      fail "No tester platform defined so supply one of the following as an argument: #{PLATFORMS.join(', ')}" if p.nil?
      p = p.to_sym
      @pattern_compilers[p].keys
    end
    alias_method :compiler_instances, :pattern_compiler_instances

    def pattern_compiler_options
      cmd = ''
      running_on_windows? ? cmd = "#{WINDOWS_PATTERN_COMPILER} -help" : cmd = "#{LINUX_PATTERN_COMPILER} -help"
      system cmd
    end
    alias_method :compiler_options, :pattern_compiler_options

    def pattern_compiler_version
      cmd = ''
      running_on_windows? ? cmd = "#{WINDOWS_PATTERN_COMPILER} -version" : cmd = "#{LINUX_PATTERN_COMPILER} -version"
      system cmd
    end
    alias_method :compiler_version, :pattern_compiler_version

    # Check if the current tester is supported
    def pattern_compiler_supported?
      PLATFORMS.include? platform ? true : false
    end
    alias_method :compiler_supported?, :pattern_compiler_supported?

    private

    def running_on_windows?
      RUBY_PLATFORM == 'i386-mingw32'
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

    def target_enabled?
      Origen.target.name.nil? ? true : false
    end
  end
end
