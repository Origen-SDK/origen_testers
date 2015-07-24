require 'spec_helper'
require 'pry'

module CompilerSpec
  class CompilerDUT
    include Testers::PatternCompilers
    include RGen::TopLevel

    attr_accessor :pinmap
    attr_reader   :ltg_compiler_options
    attr_reader   :functional_compiler_options
    attr_reader   :bist_compiler_options

    def initialize
      @ltg_compiler_options = {
        path: "#{RGen.root}/spec/patterns/atp/ltg",
        clean: false,
        location: :local,
        recursive: false,
        output_directory: "#{RGen.root}/spec/patterns/bin",
        opcode_mode: 'single',
        comments: true
      }

      @functional_compiler_options = {
        path: "#{RGen.root}/spec/patterns/atp/functional",
        clean: true,
        location: :local,
        recursive: false,
        output_directory: "#{RGen.root}/spec/patterns/bin",
        opcode_mode: 'single',
        comments: false
      }

      @bist_compiler_options = {
        clean: true,
        location: :local,
        recursive: false,
        output_directory: "#{RGen.root}/spec/patterns/bin",
        pinmap_workbook: "#{RGen.root}/spec/patterns/atp/bist/bist_pins.txt",
        opcode_mode: 'single',
        comments: false
      }
    end
  end

  describe "Ultraflex Pattern Compiler" do

    before :all do
      RGen.target.temporary = 'ultraflex_compiler'
      RGen.app.load_target!
      RGen.load_application
      $dut = CompilerDUT.new
      $dut.pinmap = "#{RGen.root}/spec/patterns/compiler_pins.txt"
      # Clean up any .PAT and .log files in our spec testing area
      Dir.glob("#{$dut.ltg_compiler_options[:output_directory]}/**/*.PAT").each do |f|
        File.delete(f)
      end
      Dir.glob("#{$dut.functional_compiler_options[:output_directory]}/**/*.PAT").each do |f|
        File.delete(f)
      end
      Dir.glob("#{$dut.ltg_compiler_options[:path]}/**/*.log").each do |f|
        File.delete(f)
      end
      Dir.glob("#{$dut.functional_compiler_options[:path]}/**/*.log").each do |f|
        File.delete(f)
      end
    end

    it "creates pattern compiler instances correctly" do
      $dut.pattern_compilers.should == {}
      $dut.add_compiler(:ltg, :ultraflex, $dut.ltg_compiler_options)
      # pattern_compiler method will show compiler instances
      # for whatever the current tester platform is enabled
      $dut.pattern_compilers.keys.should == [:ltg]
      $dut.add_compiler(:functional, :ultraflex, $dut.functional_compiler_options)
      $dut.pattern_compilers.count.should == 2
    end

    it "finds the correct number of patterns" do
      $dut.pattern_compilers[:ltg].find_jobs
      ltg_atp_count = $dut.pattern_compilers[:ltg].count
      ltg_atp_count.should == 1
    end

    it "can search the compiler job queue" do
      $dut.pattern_compilers[:ltg].jobs(/fail/).should == false
      $dut.pattern_compilers[:ltg].jobs(/idreg/).should == true
      $dut.pattern_compilers[:ltg].jobs('ls2080').should == true
      $dut.pattern_compilers[:ltg].jobs(0).should == true
      $dut.pattern_compilers[:ltg].jobs($dut.pattern_compilers[:ltg].count+1).should == false
    end

    it "can compile the expected number of patterns" do
      ltg_atp_count = $dut.pattern_compilers[:ltg].count
      ltg_atp_count.should == 1
      ltg_pat_matches = Dir.glob("#{$dut.ltg_compiler_options[:output_directory]}/**/*.PAT").count
      ltg_pat_matches.should == 0
      $dut.pattern_compilers[:ltg].run
      ltg_pat_matches = Dir.glob("#{$dut.ltg_compiler_options[:output_directory]}/**/*.PAT").count
      ltg_atp_count.should == ltg_pat_matches
    end

    it "can save log files" do
      ltg_pat_matches = Dir.glob("#{$dut.ltg_compiler_options[:output_directory]}/**/*.PAT").count
      if $dut.ltg_compiler_options[:clean] == false
        Dir.glob("#{$dut.ltg_compiler_options[:path]}/**/*.log").count.should == ltg_pat_matches
      else
        Dir.glob("#{$dut.ltg_compiler_options[:path]}/**/*.log").count.should == 0
      end
    end

    it "can find and compile patterns recursively/non-recursively in directories and lists" do
      # Clean up patterns and log files from previous spec testing
      Dir.glob("#{$dut.ltg_compiler_options[:output_directory]}/**/*.PAT").each do |f|
        File.delete(f)
      end
      Dir.glob("#{$dut.ltg_compiler_options[:path]}/**/*.log").each do |f|
        File.delete(f)
      end
      $dut.pattern_compilers[:functional].find_jobs
      functional_atp_count = $dut.pattern_compilers[:functional].count
      functional_atp_count.should == 1
      functional_pat_matches = Dir.glob("#{$dut.functional_compiler_options[:output_directory]}/**/*.PAT").count
      functional_pat_matches.should == 0
      $dut.pattern_compilers[:functional].run
      functional_pat_matches = Dir.glob("#{$dut.functional_compiler_options[:output_directory]}/**/*.PAT").count
      functional_atp_count.should == functional_pat_matches
      # Turn on the recursive flag which will find patterns and lists in sub-directories
      $dut.functional_compiler_options[:recursive] = true
      $dut.add_compiler(:functional_recursive, :ultraflex, $dut.functional_compiler_options)
      $dut.pattern_compilers[:functional_recursive].find_jobs
      functional_atp_count = $dut.pattern_compilers[:functional_recursive].count
      functional_atp_count.should == 7
      functional_pat_matches = Dir.glob("#{$dut.functional_compiler_options[:output_directory]}/**/*.PAT").count
      # Should have one pattern from previous run
      functional_pat_matches.should == 1
      $dut.pattern_compilers[:functional_recursive].run
      functional_pat_matches = Dir.glob("#{$dut.functional_compiler_options[:output_directory]}/**/*.PAT").count
      functional_atp_count.should == functional_pat_matches
    end

    it "can delete log files" do
      functional_pat_matches = Dir.glob("#{$dut.functional_compiler_options[:output_directory]}/**/*.PAT").count
      if $dut.functional_compiler_options[:clean] == false
        Dir.glob("#{$dut.functional_compiler_options[:path]}/**/*.log").count.should == functional_pat_matches
      else
        Dir.glob("#{$dut.functional_compiler_options[:path]}/**/*.log").count.should == 0
      end
    end

    it "allows users to pass files individually inside an enumeration" do
      # Clean up patterns and log files from previous spec testing
      Dir.glob("#{$dut.functional_compiler_options[:output_directory]}/**/*.PAT").each do |f|
        File.delete(f)
      end
      Dir.glob("#{$dut.functional_compiler_options[:path]}/**/*.log").each do |f|
        File.delete(f)
      end
      # This compiler instance does not specify path but does specify a pinmap
      # The pinmap passed as an option should override $dut.pinmap
      $dut.add_compiler(:bist, :ultraflex, $dut.bist_compiler_options)
      # The pinmap passed to the compiler as an option overrode the one at $dut.pinmap
      $dut.pinmap.should_not == $dut.pattern_compilers[:bist].pinmap.to_s
      bist_pattern_count = Dir["#{RGen.root}/spec/patterns/atp/bist/*.atp*"].count
      Dir["#{RGen.root}/spec/patterns/atp/bist/*.atp*"].each do |f|
        atp = Pathname.new(f)
        next unless atp.extname == '.gz' || atp.extname == '.atp'
        # Ignore patterns that do not have 'prod' in the name
        next unless atp.basename.to_s.match(/prod/)
        $dut.pattern_compilers[:bist].find_jobs(atp)
      end
      # Filtered one pattern
      $dut.pattern_compilers[:bist].count.should == 3
      # Save the compiler queue to a pattern list file for diff or run later
      $dut.pattern_compilers[:bist].to_list(name: 'bist_compile', force: true, output_directory: $dut.bist_compiler_options[:output_directory])
      $dut.pattern_compilers[:bist].run
      bist_pat_matches = Dir.glob("#{$dut.bist_compiler_options[:output_directory]}/**/*.PAT").count
      bist_pat_matches.should == bist_pattern_count - 1
      # Clean up patterns and log files from previous spec testing
      Dir.glob("#{$dut.bist_compiler_options[:output_directory]}/**/*.PAT").each do |f|
        File.delete(f)
      end
      $dut.pattern_compilers[:bist].count.should == 0
    end
    
    it "can compile a pattern list" do
      # Compile the patterns using the pattern list created earlier
      list = Pathname.new("#{$dut.bist_compiler_options[:output_directory]}/bist_compile.list")
      $dut.pattern_compilers[:bist].run(list, $dut.bist_compiler_options)
      bist_pat_matches = Dir.glob("#{$dut.bist_compiler_options[:output_directory]}/**/*.PAT").count
      # compiled patterns count should match what we had when we wrote out the pattern list
      bist_pat_matches.should == 3
    end
  end
end
