module OrigenTesters
  module Decompiler
    require 'origen_testers/igxl_based_tester'
    require 'origen_testers/smartest_based_tester'

    # Class variable to store the current known file types and the appropriate decompiler
    @@decompiler_mapping = {
      '.atp' => OrigenTesters::IGXLBasedTester,
      '.avc' => OrigenTesters::SmartestBasedTester
    }

    def self.decompile(filename, options = {})
      select_decompiler(filename, options).decompile(filename, options)
    end

    def self.decompiler_mapping
      @@decompiler_mapping
    end

    def self.select_decompiler(pattern_file, options = {})
      return options[:decompiler] if options[:decompiler]

      decompiler = decompiler_mapping[File.extname(pattern_file)]
      if decompiler.nil?
        Origen.log.error "Unknown decompiler for file extension #{File.extname(pattern_file)}"
        Origen.log.error "Please either add additional decompiler mappings to #{name}.decompiler_mapping"
        Origen.log.error 'Or provide a :decompiler option'
        fail "Unknown decompiler for file extension #{pattern_file.ext}"
      end
      decompiler
    end
  end
end
