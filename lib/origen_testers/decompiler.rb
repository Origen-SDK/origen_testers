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
      decompiler(filename, options).decompile
    end

    def self.decompiler(filename, options = {})
      if options[:decompiler]
        options[:decompiler].decompiler(filename, options)
      elsif options[:raw_input] && !options[:decompiler]
        Origen.app.fail!(message: 'Decompiler: Option :raw_input requires that the :decompiler option be specified.')
      else
        select_decompiler(filename, options).decompiler(filename, options)
      end
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
