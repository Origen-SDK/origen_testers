require 'spec_helper'
require 'pry'

module CompilerSpec
  class CompilerDUT
    include Origen::TopLevel

    include OrigenTesters::PatternCompilers

    attr_accessor :pinmap
    attr_reader :ltg_compiler_options
    attr_reader :functional_compiler_options
    attr_reader :bist_compiler_options
    attr_reader :j750_compiler_options, :j750_alt_compiler_options
    attr_accessor :v93k_compiler_options, :v93k_alt1_compiler_options, :v93k_alt2_compiler_options
    attr_accessor :empty_compiler_options

    def initialize
      add_pin :tclk
      add_pin :tdi
      add_pin :tdo
      add_pin :tms
      add_pin :reset,   reset: :drive_hi,  name: 'nvm_reset'
      add_pin :clk,     reset: :drive_hi,  name: 'nvm_clk'
      add_pin :fail,    reset: :drive_hi,  name: 'nvm_fail'
      add_pin :porta,   reset: :drive_lo,  size: 8
      add_pin :portb,   reset: :drive_lo,  size: 8, endian: :little

      # UltraFLEX-specific Pattern Compiler Setups
      #
      @ltg_compiler_options = {
        path:             "#{Origen.root}/spec/patterns/atp/ltg",
        clean:            false,
        location:         :local,
        recursive:        false,
        output_directory: "#{Origen.root}/spec/patterns/bin",
        opcode_mode:      'single',
        comments:         true
      }

      @functional_compiler_options = {
        path:             "#{Origen.root}/spec/patterns/atp/functional",
        clean:            true,
        location:         :local,
        recursive:        false,
        output_directory: "#{Origen.root}/spec/patterns/bin",
        opcode_mode:      'single',
        comments:         false,
        verbose:          true
      }

      @bist_compiler_options = {
        clean:            true,
        location:         :local,
        recursive:        false,
        output_directory: "#{Origen.root}/spec/patterns/bin",
        pinmap_workbook:  "#{Origen.root}/spec/patterns/atp/bist/bist_pins.txt",
        opcode_mode:      'single',
        comments:         false
      }

      # J50-specifc Pattern Compiler Setups
      #
      @j750_compiler_options = {
        path:             "#{Origen.root}/spec/patterns/atp/j750",
        clean:            true,
        location:         :local,
        recursive:        false,
        output_directory: "#{Origen.root}/spec/patterns/bin/j750",
        pinmap_workbook:  "#{Origen.root}/spec/patterns/atp/bist/bist_pins.txt",
        opcode_mode:      'single',
        comments:         false
      }

      @j750_alt_compiler_options = {
        clean:       true,
        location:    :local,
        recursive:   false,
        opcode_mode: 'single',
        comments:    false
      }

      # V93K-specific Pattern Compiler Setups
      #
      @v93k_compiler_options = {
        config_dir: "#{Origen.root}/spec/patterns",
        pinconfig:  'compiler_pins.cfg',
        tmf:        'timing_map_file.tmf',
        aiv2b_opts: '-ALT -k'
      }

      @v93k_alt1_compiler_options = {
        config_dir: "#{Origen.root}/spec/patterns",
        pinconfig:  'compiler_pins.cfg',
        tmf:        'timing_map_file.tmf',
        multiport:  {
          port_bursts:   {
            p_1: 'pattern_burst_1',
            p_2: 'pat_burst_two'
          },
          port_in_focus: 'p_FOCUS',
          prefix:        'mpb'
        },
        digcap:     {
          pins: :porta,
          vps:  1,
          nrf:  1
        }
      }

      @v93k_alt2_compiler_options = {
        config_dir: "#{Origen.root}/spec/patterns",
        pinconfig:  'compiler_pins.cfg',
        tmf:        'timing_map_file.tmf',
        vbc:        'pattern_configuration_file.vbc',
        aiv2b_opts: ['-CALTE', '-k', '-z PS800'],
        multiport:  {
          port_in_focus: 'p_ONLY',
          postfix:       'pset'
        },
        digcap:     {
          pins: 'tdo',
          vps:  1,
          nrf:  1,
          char: 'Q'
        }
      }

      # Generic Pattern Compiler Setup that can be customized for specific test
      #
      @empty_compiler_options = {}
    end
  end

  class SpecSiteConfig < Origen::SiteConfig
    def configs
      []
    end
  end

  describe 'Pattern Compilers' do
    describe 'Generic Pattern Compiler' do
      before :all do
        Origen.target.temporary = -> do
          tester = OrigenTesters::V93K.new
          dut = CompilerDUT.new
        end
        Origen.load_target
      end

      it 'supports correct tester platforms' do
        dut.pattern_compiler_platforms.should == [:j750, :ultraflex, :v93k]
      end

      it 'fails if origen_testers site config not given' do
        # Temporarily re-direct site_config to empty one to mimic no origen_testers config
        Origen.instance_variable_set('@site_config', SpecSiteConfig.new)
        dut.pattern_compilers.should == {}
        msg = 'Adding a pattern compiler without site config specifying bin location not allowed'
        lambda { dut.add_pattern_compiler(:id1, :v93k, dut.v93k_compiler_options) }.should raise_error(msg)
        Origen.instance_variable_set('@site_config', nil)
        msg = 'Pinconfig file is not defined!  Pass as an option.'
        lambda { dut.add_pattern_compiler(:id2, :v93k, dut.empty_compiler_options) }.should raise_error(msg)
      end

      it 'creates pattern compiler instances correctly' do
        dut.pattern_compilers.should == {}
        dut.add_pattern_compiler(:id1, :v93k, dut.v93k_compiler_options)
        dut.pattern_compilers.keys.should == [:id1]
        dut.pattern_compiler_instances.should == [:id1]
        dut.pattern_compilers.count.should == 1

        dut.pinmap = "#{Origen.root}/spec/patterns/compiler_pins.txt"
        dut.add_pattern_compiler(:id1, :j750, dut.v93k_compiler_options)
        dut.add_pattern_compiler(:id2, :j750, dut.v93k_compiler_options)
        dut.pattern_compilers.keys.should == [:id1]
        dut.pattern_compiler_instances.should == [:id1]
        dut.pattern_compilers.count.should == 1
        dut.pattern_compilers(platform: :j750).keys.should == [:id1, :id2]
        dut.pattern_compiler_instances(:j750).should == [:id1, :id2]
        dut.pattern_compiler_instances('j750').should == [:id1, :id2]
        dut.pattern_compiler_instances.should == [:id1]
        dut.pattern_compilers(platform: :j750).count.should == 2
        dut.pattern_compilers(platform: :ultraflex).keys.should == []
        dut.pattern_compiler_instances(:ultraflex).should == []
        dut.pattern_compilers(platform: :ultraflex).count.should == 0

        dut.add_pattern_compiler(:id2, :ultraflex, dut.ltg_compiler_options)
        dut.pattern_compilers.keys.should == [:id1]
        dut.pattern_compilers(platform: :j750).keys.should == [:id1, :id2]
        dut.pattern_compiler_instances(:j750).should == [:id1, :id2]
        dut.pattern_compilers(platform: :j750).count.should == 2
        dut.pattern_compilers(platform: :ultraflex).keys.should == [:id2]
        dut.pattern_compiler_instances(:ultraflex).should == [:id2]
        dut.pattern_compilers(platform: :ultraflex).count.should == 1

        dut.pattern_compilers(:id1).should.nil?
        msg = "undefined method `inspect_options' for nil:NilClass"
        lambda { dut.pattern_compilers(:id11) }.should raise_error(msg)
        dut.pattern_compilers(:id1, platform: :j750).should.nil?
        lambda { dut.pattern_compilers(:id11, platform: :j750) }.should raise_error(msg)
      end

      it 'can set default compiler' do
        dut.default_pattern_compiler.should.nil?
        dut.add_pattern_compiler(:id2, :v93k, dut.v93k_compiler_options.merge(default: true))
        dut.default_pattern_compiler.should == :id2
        dut.set_default_pattern_compiler(:id1)
        dut.default_pattern_compiler.should == :id1

        dut.default_pattern_compiler(:j750).should.nil?
        dut.set_default_pattern_compiler(:id2, :j750)
        dut.default_pattern_compiler(:j750).should == :id2
        dut.default_pattern_compiler.should == :id1
      end

      it 'fails to create duplicate compiler instance name' do
        lambda { dut.add_pattern_compiler(:id1, :v93k) }.should raise_error
      end

      it 'fails to create compiler instance for invalid tester platform' do
        lambda { dut.add_pattern_compiler(:id3, :d10) }.should raise_error
      end

      it 'can print options and version' do
        dut.pattern_compiler_options(:v93k)
        dut.pattern_compiler_version(:v93k)
      end

      it 'can delete pattern compilers' do
        dut.add_pattern_compiler(:id3, :v93k, dut.v93k_compiler_options)
        dut.pattern_compilers.keys.should == [:id1, :id2, :id3]
        dut.pattern_compilers.count.should == 3

        dut.pattern_compiler_instances(:j750).should == [:id1, :id2]
        dut.pattern_compilers(platform: :j750).count.should == 2

        dut.delete_pattern_compiler(:id2)
        dut.pattern_compilers.keys.should == [:id1, :id3]
        dut.pattern_compilers.count.should == 2

        dut.delete_pattern_compilers
        dut.pattern_compilers.keys.should == []
        dut.pattern_compilers.count.should == 0

        dut.delete_pattern_compiler(:id1, :j750)
        dut.pattern_compilers(platform: :j750).keys.should == [:id2]
        dut.pattern_compilers(platform: :j750).count.should == 1

        dut.delete_pattern_compilers(:j750)
        dut.pattern_compilers(platform: :j750).keys.should == []
        dut.pattern_compilers(platform: :j750).count.should == 0
      end

      it 'can detect non-tester' do
        msg = 'No tester platform defined, supply one of the following as an argument: j750, ultraflex, v93k'
        lambda { dut.pattern_compiler_instances(nil) }.should raise_error(msg)

        msg = 'Platform v93k is not valid, please choose from j750, ultraflex, v93k'
        lambda { dut.platform_compiler(:d10) }.should raise_error(msg)
      end
    end

    describe "Generic Pattern Compiler cont'd" do
      before :each do
        Origen.environment.temporary = 'empty'
        Origen.target.temporary = -> do
          dut = CompilerDUT.new
        end
        Origen.load_target
      end

      it 'fails if tester not targeted' do
        msg = 'No tester instantiated, $tester is set to nil'
        lambda { dut.pattern_compilers }.should raise_error(msg)
      end
    end

    describe 'V93K Pattern Compiler' do
      before :each do
        Origen.target.temporary = -> do
          tester = OrigenTesters::V93K.new
          dut = CompilerDUT.new
        end
        Origen.load_target
      end

      it 'fails if pinconfig not specified' do
        msg = 'Pinconfig file is not defined!  Pass as an option.'
        lambda { dut.add_pattern_compiler(:id1, :v93k, dut.empty_compiler_options) }.should raise_error(msg)
      end

      it 'fails if pinconfig not a file' do
        dut.empty_compiler_options[:pinconfig] = 'asdfghjkl'
        msg = 'Pinconfig is not a file!'
        lambda { dut.add_pattern_compiler(:id1, :v93k, dut.empty_compiler_options) }.should raise_error(msg)
      end

      it 'fails if timing map file (tmf) not specified' do
        dut.empty_compiler_options[:pinconfig] = "#{Origen.root}/spec/patterns/compiler_pins.cfg"
        msg = 'Timing Map File (tmf) is not defined!  Pass as an option.'
        lambda { dut.add_pattern_compiler(:id1, :v93k, dut.empty_compiler_options) }.should raise_error(msg)
      end

      it 'fails if timing map file (tmf) not a file' do
        dut.empty_compiler_options[:pinconfig] = "#{Origen.root}/spec/patterns/compiler_pins.cfg"
        dut.empty_compiler_options[:tmf] = 'asdfghjkl'
        msg = 'Timing Map File (tmf) is not a file!'
        lambda { dut.add_pattern_compiler(:id1, :v93k, dut.empty_compiler_options) }.should raise_error(msg)
      end

      it 'builds pinconfig_file and tmf_file paths correctly' do
        # Absolute Paths given
        p = "#{Origen.root}/spec/patterns/compiler_pins.cfg"
        t = "#{Origen.root}/spec/patterns/timing_map_file.tmf"
        dut.empty_compiler_options[:config_dir] = '/should/not/use/this/path/'
        dut.empty_compiler_options[:pinconfig] = p
        dut.empty_compiler_options[:tmf] = t
        dut.add_pattern_compiler(:id1, :v93k, dut.empty_compiler_options)
        dut.pattern_compilers[:id1].pinconfig_file.to_s.should == p
        dut.pattern_compilers[:id1].tmf_file.to_s.should == t
        dut.pattern_compilers[:id1].name.should == :id1

        # File name with param-specific directory (pinconfig_dir and tmf_dir)
        pd = "#{Origen.root}/spec/patterns/"
        pf = 'compiler_pins.cfg'
        td = "#{Origen.root}/spec/patterns"
        tf = 'timing_map_file.tmf'
        dut.empty_compiler_options[:config_dir] = '/should/not/use/this/path/'
        dut.empty_compiler_options[:pinconfig_dir] = pd
        dut.empty_compiler_options[:pinconfig] = pf
        dut.empty_compiler_options[:tmf_dir] = td
        dut.empty_compiler_options[:tmf] = tf
        dut.add_pattern_compiler(:id2, :v93k, dut.empty_compiler_options)
        dut.pattern_compilers[:id2].pinconfig_file.to_s.should == p
        dut.pattern_compilers[:id2].tmf_file.to_s.should == t

        # File name with common directory (config_dir) only
        cd = "#{Origen.root}/spec/patterns/"
        pf = 'compiler_pins.cfg'
        tf = 'timing_map_file.tmf'
        dut.empty_compiler_options[:config_dir] = cd
        dut.empty_compiler_options[:pinconfig_dir] = nil
        dut.empty_compiler_options[:pinconfig] = pf
        dut.empty_compiler_options[:tmf_dir] = nil
        dut.empty_compiler_options[:tmf] = tf
        dut.add_pattern_compiler(:id3, :v93k, dut.empty_compiler_options)
        dut.pattern_compilers[:id3].pinconfig_file.to_s.should == p
        dut.pattern_compilers[:id3].tmf_file.to_s.should == t

        # File name without directory (should resolve to path relative to application root
        pf = 'spec/patterns/compiler_pins.cfg'
        tf = 'spec/patterns/timing_map_file.tmf'
        dut.empty_compiler_options[:config_dir] = nil
        dut.empty_compiler_options[:pinconfig_dir] = nil
        dut.empty_compiler_options[:pinconfig] = pf
        dut.empty_compiler_options[:tmf_dir] = nil
        dut.empty_compiler_options[:tmf] = tf
        dut.add_pattern_compiler(:id4, :v93k, dut.empty_compiler_options)
        dut.pattern_compilers[:id4].pinconfig_file.to_s.should == p
        dut.pattern_compilers[:id4].tmf_file.to_s.should == t
      end

      it 'finds the correct number of patterns' do
        dut.pattern_compilers.should == {}
        dut.add_pattern_compiler(:id1, :v93k, dut.v93k_compiler_options)

        # Call find_jobs with no arguments
        msg = 'Pattern path is set to nil! Pass in a valid file (.avc, .avc.gz, .list) or a valid directory'
        lambda { dut.pattern_compilers[:id1].find_jobs }.should raise_error(msg)

        # Call find_jobs with file name of pattern that does not exist
        path_to_pattern = "#{Origen.root}/spec/patterns/avc/invalid.avc"
        msg = 'Pattern path does not exist! Pass in a valid file (.avc, .avc.gz, .list) or a valid directory'
        lambda { dut.pattern_compilers[:id1].find_jobs(path_to_pattern) }.should raise_error(msg)

        # Call find_jobs with invalid file name (not .avc or .list)
        path_to_pattern = "#{Origen.root}/spec/patterns/avc/bitmap.invalid"
        msg = 'Did not fild a valid file to compile! Pass in a valid file (.avc, .avc.gz, .list) or a valid directory'
        lambda { dut.pattern_compilers[:id1].find_jobs(path_to_pattern) }.should raise_error(msg)

        # Call find_jobs with single AVC file with no Captures
        path_to_pattern = "#{Origen.root}/spec/patterns/avc/bitmap.avc"
        dut.pattern_compilers[:id1].find_jobs(path_to_pattern)
        dut.pattern_compilers[:id1].count.should == 1
        dut.pattern_compilers[:id1].jobs
        dut.pattern_compilers[:id1].jobs('blah')
        msg = 'Search argument must be of type String, Regexp, or Integer'
        lambda { dut.pattern_compilers[:id1].jobs(['blah']) }.should raise_error(msg)

        # Add another job single AVC file with no Captures
        path_to_pattern = "#{Origen.root}/spec/patterns/avc/v93k_workout.avc"
        dut.pattern_compilers[:id1].find_jobs(path_to_pattern)
        dut.pattern_compilers[:id1].count.should == 2
        dut.pattern_compilers[:id1].clear

        # Call find_jobs with file name of list that does not exist
        path_to_list = "#{Origen.root}/spec/patterns/avc/invalid.list"
        msg = 'Pattern path does not exist! Pass in a valid file (.avc, .avc.gz, .list) or a valid directory'
        lambda { dut.pattern_compilers[:id1].find_jobs(path_to_list) }.should raise_error(msg)

        # Call find_jobs with list file
        dut.v93k_compiler_options[:avc_dir] = 'AVC2'
        dut.v93k_compiler_options[:binl_dir] = './BINL2'
        dut.v93k_compiler_options[:vbc] = 'pattern_configuration_file.vbc'
        dut.add_pattern_compiler(:id2, :v93k, dut.v93k_compiler_options)
        path_to_list = "#{Origen.root}/spec/patterns/avc/v93k.list"
        dut.pattern_compilers[:id2].find_jobs(path_to_list)
        dut.pattern_compilers[:id2].count.should == 1
        dut.pattern_compilers[:id2].clear

        # Call find_jobs with directory
        path_to_directory = "#{Origen.root}/spec/patterns/avc/"
        dut.pattern_compilers[:id1].find_jobs(path_to_directory)
        dut.pattern_compilers[:id1].count.should == 1
        dut.pattern_compilers[:id1].clear
      end

      it 'implements multiport setup' do
        dut.pattern_compilers.should == {}
        dut.add_pattern_compiler(:id1, :v93k, dut.v93k_alt1_compiler_options)
        dut.add_pattern_compiler(:id2, :v93k, dut.v93k_alt2_compiler_options)
        dut.add_pattern_compiler(:id3, :v93k, dut.v93k_compiler_options)

        dut.pattern_compilers[:id1].multiport?.should == true
        dut.pattern_compilers[:id2].multiport?.should == true
        dut.pattern_compilers[:id3].multiport?.should == false

        dut.pattern_compilers[:id1].instance_variable_set('@max_avcfilename_size', 9)
        aiv_pat_line = 'PATTERNS name       port     tmf_file'
        dut.pattern_compilers[:id1].render_aiv_patterns_header.should == aiv_pat_line
        aiv_pat_line = '         spec_test  p_FOCUS  timing_map_file.tmf'
        dut.pattern_compilers[:id1].render_aiv_patterns_entry('spec_test').should == aiv_pat_line
        aiv_mpb_lines = ['']
        aiv_mpb_lines << 'MULTI_PORT_BURST mpb_spec_test'
        aiv_mpb_lines << 'PORTS p_FOCUS    p_1              p_2            '
        aiv_mpb_lines << '      spec_test  pattern_burst_1  pat_burst_two  '
        dut.pattern_compilers[:id1].multiport.render_aiv_lines('spec_test').should == aiv_mpb_lines

        dut.pattern_compilers[:id2].instance_variable_set('@max_avcfilename_size', 9)
        aiv_pat_line = 'PATTERNS name       port    tmf_file'
        dut.pattern_compilers[:id2].render_aiv_patterns_header.should == aiv_pat_line
        aiv_pat_line = '         spec_test  p_ONLY  timing_map_file.tmf'
        dut.pattern_compilers[:id2].render_aiv_patterns_entry('spec_test').should == aiv_pat_line
        aiv_mpb_lines = ['']
        aiv_mpb_lines << 'MULTI_PORT_BURST spec_test_pset'
        aiv_mpb_lines << 'PORTS p_ONLY     '
        aiv_mpb_lines << '      spec_test  '
        dut.pattern_compilers[:id2].multiport.render_aiv_lines('spec_test').should == aiv_mpb_lines
      end

      it 'implements digital capture setup' do
        dut.pattern_compilers.should == {}
        dut.add_pattern_compiler(:id1, :v93k, dut.v93k_alt1_compiler_options)
        dut.add_pattern_compiler(:id2, :v93k, dut.v93k_alt2_compiler_options)
        dut.add_pattern_compiler(:id3, :v93k, dut.v93k_compiler_options)
        dut.pattern_compilers[:id1].digcap?.should == true
        dut.pattern_compilers[:id2].digcap?.should == true
        dut.pattern_compilers[:id3].digcap?.should == false

        dut.v93k_alt1_compiler_options[:digcap][:pins] = nil
        dut.add_pattern_compiler(:id4, :v93k, dut.v93k_alt1_compiler_options)
        msg = 'Must specifiy pins and vps for digcap setup!'
        lambda { dut.pattern_compilers[:id4].digcap? }.should raise_error(msg)
        dut.v93k_alt2_compiler_options[:digcap][:vps] = nil
        dut.add_pattern_compiler(:id5, :v93k, dut.v93k_alt1_compiler_options)
        msg = 'Must specifiy pins and vps for digcap setup!'
        lambda { dut.pattern_compilers[:id5].digcap? }.should raise_error(msg)
        dut.v93k_alt1_compiler_options[:digcap][:pins] = %w(A B C)
        dut.add_pattern_compiler(:id6, :v93k, dut.v93k_alt1_compiler_options)
        msg = 'Digcap Pins does not support array yet'
        lambda { dut.pattern_compilers[:id6].digcap.num_pins }.should raise_error(msg)

        dut.pattern_compilers[:id1].digcap.num_pins.should == 8
        dut.pattern_compilers[:id1].digcap.capture_string == ' CCCCCCCC '
        dut.pattern_compilers[:id2].digcap.num_pins.should == 1
        dut.pattern_compilers[:id2].digcap.capture_string.should == ' Q '

        path_to_pattern = "#{Origen.root}/spec/patterns/avc/bitmap.avc"
        dut.pattern_compilers[:id1].find_jobs(path_to_pattern)
        dut.pattern_compilers[:id1].instance_variable_set('@vec_per_frame', bitmap: 0)
        dut.pattern_compilers[:id1].digcap.empty?.should == true
        dut.pattern_compilers[:id1].vec_per_frame[:bitmap].should == 0
        dut.pattern_compilers[:id1].clear
        dut.pattern_compilers[:id2].find_jobs(path_to_pattern)
        dut.pattern_compilers[:id2].instance_variable_set('@vec_per_frame', bitmap: 0)
        dut.pattern_compilers[:id2].digcap.empty?.should == true
        dut.pattern_compilers[:id2].vec_per_frame[:bitmap].should == 0
        dut.pattern_compilers[:id2].clear

        path_to_pattern = "#{Origen.root}/spec/patterns/avc/v93k_workout.avc"
        dut.pattern_compilers[:id1].find_jobs(path_to_pattern)
        dut.pattern_compilers[:id1].instance_variable_set('@vec_per_frame', v93k_workout: 1)
        dut.pattern_compilers[:id1].digcap.empty?.should == false
        dut.pattern_compilers[:id1].vec_per_frame[:v93k_workout].should == 1
        dut.pattern_compilers[:id1].clear
        dut.pattern_compilers[:id2].find_jobs(path_to_pattern)
        dut.pattern_compilers[:id2].instance_variable_set('@vec_per_frame', v93k_workout: 0)
        dut.pattern_compilers[:id2].digcap.empty?.should == true
        dut.pattern_compilers[:id2].vec_per_frame[:v93k_workout].should == 0
        dut.pattern_compilers[:id2].clear

        path_to_pattern = "#{Origen.root}/spec/patterns/avc/test_store.avc"
        dut.pattern_compilers[:id1].find_jobs(path_to_pattern)
        dut.pattern_compilers[:id1].instance_variable_set('@vec_per_frame', test_store: 0)
        dut.pattern_compilers[:id1].digcap.empty?.should == true
        dut.pattern_compilers[:id1].vec_per_frame[:test_store].should == 0
        dut.pattern_compilers[:id1].clear
        dut.pattern_compilers[:id2].find_jobs(path_to_pattern)
        dut.pattern_compilers[:id2].instance_variable_set('@vec_per_frame', test_store: 2)
        dut.pattern_compilers[:id2].digcap.empty?.should == false
        dut.pattern_compilers[:id2].vec_per_frame[:test_store].should == 2
        dut.pattern_compilers[:id2].clear

        dut.pattern_compilers[:id1].instance_variable_set('@max_avcfilename_size', 9)
        dut.pattern_compilers[:id1].instance_variable_set('@vec_per_frame', spec_test: 5)
        dut.pattern_compilers[:id1].instance_variable_set('@avc_files', ['spec_test'])
        aiv_digcap_lines = ['']
        aiv_digcap_lines << 'AI_DIGCAP_SETTINGS {'
        aiv_digcap_lines << 'variable       label      vec_per_frame  vec_per_sample  nr_frames  {pins};'
        aiv_digcap_lines << 'spec_test_var  spec_test  5              1               1          {porta};'
        aiv_digcap_lines << '};'
        dut.pattern_compilers[:id1].digcap.render_aiv_lines.should == aiv_digcap_lines
      end

      it 'handles misc options' do
        dut.pattern_compilers.should == {}
        dut.v93k_compiler_options[:output_directory] = "#{Origen.root!}/spec/patterns/avc/output"
        dut.v93k_compiler_options[:tmp_dir] = "#{Origen.root!}/spec/patterns/avc/output/tmp"
        dut.v93k_compiler_options[:includes] = ['timing_include_file.tmf']
        dut.add_pattern_compiler(:id1, :v93k, dut.v93k_compiler_options)
        path_to_pattern = "#{Origen.root}/spec/patterns/avc/bitmap.avc"
        dut.pattern_compilers[:id1].find_jobs(path_to_pattern)
        dut.pattern_compilers[:id1].inspect_jobs(0)

        dut.v93k_compiler_options[:aiv2b_opts] = { opts: '-CALTE' }
        dut.add_pattern_compiler(:id2, :v93k, dut.v93k_compiler_options)
        path_to_pattern = "#{Origen.root}/spec/patterns/avc/bitmap.avc"
        msg = 'aiv2b options must be an array or string'
        lambda { dut.pattern_compilers[:id2].find_jobs(path_to_pattern) }.should raise_error(msg)
      end

      unless Origen.running_on_windows?
        it "doesn't run empty job list" do
          dut.pattern_compilers.should == {}
          dut.v93k_compiler_options[:clean] = true
          dut.add_pattern_compiler(:id1, :v93k, dut.v93k_compiler_options)
          dut.pattern_compilers[:id1].run
        end

        it 'runs existing aiv file' do
          dut.pattern_compilers.should == {}
          dut.v93k_compiler_options[:clean] = true
          dut.add_pattern_compiler(:id1, :v93k, dut.v93k_compiler_options)

          path_to_aiv = "#{Origen.root}/spec/patterns/atp/does_not_exist/bitmap.aiv"
          msg = 'File does not exist!  Please specify existing aiv file.'
          lambda { dut.pattern_compilers[:id1].run(path_to_aiv) }.should raise_error(msg)
          dut.pattern_compilers[:id1].clear
          path_to_aiv = "#{Origen.root}/spec/patterns/bitmap.aiv"
          dut.pattern_compilers[:id1].run(path_to_aiv, ignore_ready: true, verbose: true)
        end
      end
    end

    unless Origen.running_on_windows?
      describe 'Runner' do
        before :all do
          Origen.target.temporary = -> do
            tester = OrigenTesters::V93K.new
            dut = CompilerDUT.new
          end
          Origen.load_target
        end

        it 'can dispatch from the Runner' do
          path_to_pattern = "#{Origen.root}/spec/patterns/avc/bitmap.avc"
          dut.add_pattern_compiler(:id1, :v93k, dut.v93k_compiler_options)

          OrigenTesters::PatternCompilers::Runner.run_compiler(path_to_pattern, compiler_instance: :id1)

          msg = "Pattern Compiler instance 'id2' does not exist for this tester, choose from (id1) or change tester target."
          lambda { OrigenTesters::PatternCompilers::Runner.run_compiler(path_to_pattern, compiler_instance: :id2) }.should raise_error(msg)
          OrigenTesters::PatternCompilers::Runner.run_compiler(path_to_pattern)

          dut.add_pattern_compiler(:id2, :v93k, dut.v93k_compiler_options)
          msg = "No 'default' Pattern Compiler defined, choose from (id1, id2) or set one to be the default."
          lambda { OrigenTesters::PatternCompilers::Runner.run_compiler(path_to_pattern) }.should raise_error(msg)

          dut.add_pattern_compiler(:default, :v93k, dut.v93k_compiler_options)
          OrigenTesters::PatternCompilers::Runner.run_compiler(path_to_pattern)

          dut.set_default_pattern_compiler(:id2)
          OrigenTesters::PatternCompilers::Runner.run_compiler(path_to_pattern)
          OrigenTesters::PatternCompilers::Runner.run_compiler(path_to_pattern, compiler_instance: :id1)
        end
      end
  end

    describe 'J750 Pattern Compiler' do
      before :all do
        Origen.target.temporary = -> do
          tester = OrigenTesters::J750.new
          dut = CompilerDUT.new
        end
        Origen.load_target
        dut.pinmap = "#{Origen.root}/spec/patterns/compiler_pins.txt"

        #      # Clean up any .PAT and .log files in our spec testing area
        #      Dir.glob("#{dut.j750_compiler_options[:output_directory]}/**/*.PAT").each do |f|
        #        File.delete(f)
        #      end
        #      Dir.glob("#{dut.j750_alt_compiler_options[:output_directory]}/**/*.PAT").each do |f|
        #        File.delete(f)
        #      end
        #      Dir.glob("#{dut.j750_compiler_options[:path]}/**/*.log").each do |f|
        #        File.delete(f)
        #      end
        #      Dir.glob("#{dut.j750_alt_compiler_options[:path]}/**/*.log").each do |f|
        #        File.delete(f)
        #      end
      end

      it 'fails if pinmap not specified' do
        pinmap = dut.pinmap
        dut.pinmap = nil
        msg = 'Pinmap is not defined!  Pass as an option or set $dut.pinmap.'
        lambda { dut.add_pattern_compiler(:id1, :j750, dut.empty_compiler_options) }.should raise_error(msg)
        dut.pinmap = pinmap
      end

      it 'fails if dut.pinmap not a file' do
        pinmap = dut.pinmap
        dut.pinmap = 'asdfghjkl'
        msg = 'Pinmap is not a file!'
        lambda { dut.add_pattern_compiler(:id1, :j750, dut.empty_compiler_options) }.should raise_error(msg)
        dut.pinmap = pinmap
      end

      it 'fails if pinmap not a file' do
        pinmap = dut.pinmap
        dut.pinmap = nil
        dut.empty_compiler_options[:pinmap_workbook] = 'asdfghjkl'
        msg = 'Pinmap is not a file!'
        lambda { dut.add_pattern_compiler(:id1, :j750, dut.empty_compiler_options) }.should raise_error(msg)
        dut.pinmap = pinmap
      end

      it 'fails if pinmap not a file' do
        pinmap = dut.pinmap
        dut.empty_compiler_options[:pinmap_workbook] = nil
        dut.add_pattern_compiler(:id1, :j750, dut.empty_compiler_options)
        dut.pattern_compilers[:id1].pinmap.to_s.should == pinmap
        dut.delete_pattern_compiler(:id1)
      end

      it 'creates pattern compiler instances correctly' do
        dut.pattern_compilers.should == {}
        dut.add_pattern_compiler(:id1, :j750, dut.j750_compiler_options)
        dut.pattern_compilers.keys.should == [:id1]
        dut.add_pattern_compiler(:id2, :j750, dut.j750_alt_compiler_options)
        dut.pattern_compilers.count.should == 2
      end

      it 'fails if there is no path given' do
        msg = 'Pattern path is set to nil, pass in a valid file (.atp or .atp.gz) or a valid directory'
        lambda { dut.pattern_compilers[:id2].find_jobs }.should raise_error(msg)
      end

      it 'reads site_config correctly' do
        OrigenTesters::PatternCompilers::J750PatternCompiler.linux_compiler.should == "ruby \#{Origen.root!}/spec/compilers/j750compiler.rb"
        OrigenTesters::PatternCompilers::J750PatternCompiler.windows_compiler.should == "ruby \#{Origen.root!}/spec/compilers/j750compiler.rb"
        OrigenTesters::PatternCompilers::J750PatternCompiler.atpc_setup.should.nil?
        OrigenTesters::PatternCompilers::J750PatternCompiler.compiler.should == "ruby \#{Origen.root!}/spec/compilers/j750compiler.rb"
        cmd = OrigenTesters::PatternCompilers::J750PatternCompiler.compiler_cmd
        OrigenTesters::PatternCompilers::J750PatternCompiler.compiler_options.should == "#{cmd} -help"
        OrigenTesters::PatternCompilers::J750PatternCompiler.compiler_version.should == "#{cmd} -version"
      end

      unless Origen.running_on_windows?
        it 'prints empty msg when run empty joblist' do
          dut.pattern_compilers[:id1].run
        end
    end

      it 'finds the correct number of patterns' do
        dut.pattern_compilers[:id1].find_jobs
        j750_atp_count = dut.pattern_compilers[:id1].count
        j750_atp_count.should == 2
      end

      it 'can search the compiler job queue' do
        dut.pattern_compilers[:id1].jobs(/fail/).should == false
        dut.pattern_compilers[:id1].jobs(/idreg/).should == true
        dut.pattern_compilers[:id1].jobs('ls2080').should == true
        dut.pattern_compilers[:id1].jobs(0).should == true
        dut.pattern_compilers[:id1].jobs(dut.pattern_compilers[:id1].count + 1).should == false
      end

      unless Origen.running_on_windows?
        it 'can compile the expected number of patterns' do
          j750_atp_count = dut.pattern_compilers[:id1].count
          j750_atp_count.should == 2
          j750_pat_matches = Dir.glob("#{dut.j750_compiler_options[:output_directory]}/**/*.PAT").count
          j750_pat_matches.should == 0
          dut.pattern_compilers[:id1].run
          j750_pat_matches = Dir.glob("#{dut.j750_compiler_options[:output_directory]}/**/*.PAT").count
          j750_atp_count.should == j750_pat_matches
        end
      end

      ##      it 'creates pattern compiler instances correctly' do
      ##        dut.pattern_compilers.should == {}
      ##        dut.add_pattern_compiler(:j750, :j750, dut.v93k_compiler_options)
      ##        dut.pattern_compilers.keys.should == [:j750]
      ##      end
    end

    describe 'Ultraflex Pattern Compiler' do
      before :all do
        Origen.target.temporary = -> do
          tester = OrigenTesters::UltraFLEX.new
          dut = CompilerDUT.new
        end
        Origen.load_target
        dut.pinmap = "#{Origen.root}/spec/patterns/compiler_pins.txt"

        # Clean up any .PAT and .log files in our spec testing area
        Dir.glob("#{dut.ltg_compiler_options[:output_directory]}/**/*.PAT").each do |f|
          File.delete(f)
        end
        Dir.glob("#{dut.functional_compiler_options[:output_directory]}/**/*.PAT").each do |f|
          File.delete(f)
        end
        Dir.glob("#{dut.ltg_compiler_options[:path]}/**/*.log").each do |f|
          File.delete(f)
        end
        Dir.glob("#{dut.functional_compiler_options[:path]}/**/*.log").each do |f|
          File.delete(f)
        end
      end

      it 'fails if pinmap not specified' do
        pinmap = dut.pinmap
        dut.pinmap = nil
        msg = 'Pinmap is not defined!  Pass as an option or set $dut.pinmap.'
        lambda { dut.add_pattern_compiler(:id1, :ultraflex, dut.empty_compiler_options) }.should raise_error(msg)
        dut.pinmap = pinmap
      end

      it 'fails if dut.pinmap not a file' do
        pinmap = dut.pinmap
        dut.pinmap = 'asdfghjkl'
        msg = 'Pinmap is not a file!'
        lambda { dut.add_pattern_compiler(:id1, :ultraflex, dut.empty_compiler_options) }.should raise_error(msg)
        dut.pinmap = pinmap
      end

      it 'fails if pinmap not a file' do
        pinmap = dut.pinmap
        dut.pinmap = nil
        dut.empty_compiler_options[:pinmap_workbook] = 'asdfghjkl'
        msg = 'Pinmap is not a file!'
        lambda { dut.add_pattern_compiler(:id1, :ultraflex, dut.empty_compiler_options) }.should raise_error(msg)
        dut.pinmap = pinmap
      end

      it 'reads site_config correctly' do
        OrigenTesters::PatternCompilers::UltraFLEXPatternCompiler.linux_compiler.should == "ruby \#{Origen.root!}/spec/compilers/atpcompiler.rb"
        OrigenTesters::PatternCompilers::UltraFLEXPatternCompiler.windows_compiler.should == "ruby \#{Origen.root!}/spec/compilers/atpcompiler.rb"
        OrigenTesters::PatternCompilers::UltraFLEXPatternCompiler.atpc_setup.should.nil?
        OrigenTesters::PatternCompilers::UltraFLEXPatternCompiler.compiler.should == "ruby \#{Origen.root!}/spec/compilers/atpcompiler.rb"
        cmd = OrigenTesters::PatternCompilers::UltraFLEXPatternCompiler.compiler_cmd
        OrigenTesters::PatternCompilers::UltraFLEXPatternCompiler.compiler_options.should == "#{cmd} -help"
        OrigenTesters::PatternCompilers::UltraFLEXPatternCompiler.compiler_version.should == "#{cmd} -version"
      end

      it 'creates pattern compiler instances correctly' do
        dut.pattern_compilers.should == {}
        dut.add_pattern_compiler(:ltg, :ultraflex, dut.ltg_compiler_options)
        dut.pattern_compilers.keys.should == [:ltg]
        dut.add_pattern_compiler(:functional, :ultraflex, dut.functional_compiler_options)
        dut.pattern_compilers.count.should == 2
      end

      it 'finds the correct number of patterns' do
        dut.pattern_compilers[:ltg].find_jobs
        ltg_atp_count = dut.pattern_compilers[:ltg].count
        ltg_atp_count.should == 1
      end

      it 'can search the compiler job queue' do
        dut.pattern_compilers[:ltg].jobs(/fail/).should == false
        dut.pattern_compilers[:ltg].jobs(/idreg/).should == true
        dut.pattern_compilers[:ltg].jobs('ls2080').should == true
        dut.pattern_compilers[:ltg].jobs(0).should == true
        dut.pattern_compilers[:ltg].jobs(dut.pattern_compilers[:ltg].count + 1).should == false
      end

      unless Origen.running_on_windows?
        it 'can compile the expected number of patterns' do
          ltg_atp_count = dut.pattern_compilers[:ltg].count
          ltg_atp_count.should == 1
          ltg_pat_matches = Dir.glob("#{dut.ltg_compiler_options[:output_directory]}/**/*.PAT").count
          ltg_pat_matches.should == 0
          dut.pattern_compilers[:ltg].run
          ltg_pat_matches = Dir.glob("#{dut.ltg_compiler_options[:output_directory]}/**/*.PAT").count
          ltg_atp_count.should == ltg_pat_matches
        end
      end

      it 'can save log files' do
        ltg_pat_matches = Dir.glob("#{dut.ltg_compiler_options[:output_directory]}/**/*.PAT").count
        if dut.ltg_compiler_options[:clean] == false
          Dir.glob("#{dut.ltg_compiler_options[:path]}/**/*.log").count.should == ltg_pat_matches
        else
          Dir.glob("#{dut.ltg_compiler_options[:path]}/**/*.log").count.should == 0
        end
      end

      unless Origen.running_on_windows?
        it 'can find and compile patterns recursively/non-recursively in directories and lists' do
          # Clean up patterns and log files from previous spec testing
          Dir.glob("#{dut.ltg_compiler_options[:output_directory]}/**/*.PAT").each do |f|
            File.delete(f)
          end
          Dir.glob("#{dut.ltg_compiler_options[:path]}/**/*.log").each do |f|
            File.delete(f)
          end
          dut.pattern_compilers[:functional].find_jobs
          functional_atp_count = dut.pattern_compilers[:functional].count
          functional_atp_count.should == 2
          functional_pat_matches = Dir.glob("#{dut.functional_compiler_options[:output_directory]}/**/*.PAT").count
          functional_pat_matches.should == 0
          dut.pattern_compilers[:functional].run
          functional_pat_matches = Dir.glob("#{dut.functional_compiler_options[:output_directory]}/**/*.PAT").count
          functional_atp_count.should == functional_pat_matches
          # Turn on the recursive flag which will find patterns and lists in sub-directories
          dut.functional_compiler_options[:recursive] = true
          dut.add_pattern_compiler(:functional_recursive, :ultraflex, dut.functional_compiler_options)
          dut.pattern_compilers[:functional_recursive].find_jobs
          functional_atp_count = dut.pattern_compilers[:functional_recursive].count
          functional_atp_count.should == 8
          functional_pat_matches = Dir.glob("#{dut.functional_compiler_options[:output_directory]}/**/*.PAT").count
          # Should have one pattern from previous run
          functional_pat_matches.should == 2
          dut.pattern_compilers[:functional_recursive].run
          functional_pat_matches = Dir.glob("#{dut.functional_compiler_options[:output_directory]}/**/*.PAT").count
          functional_atp_count.should == functional_pat_matches
        end
    end

      it 'can delete log files' do
        functional_pat_matches = Dir.glob("#{dut.functional_compiler_options[:output_directory]}/**/*.PAT").count
        if dut.functional_compiler_options[:clean] == false
          Dir.glob("#{$dut.functional_compiler_options[:path]}/**/*.log").count.should == functional_pat_matches
        else
          Dir.glob("#{$dut.functional_compiler_options[:path]}/**/*.log").count.should == 0
        end
      end

      unless Origen.running_on_windows?
        it 'allows users to pass files individually inside an enumeration' do
          # Clean up patterns and log files from previous spec testing
          Dir.glob("#{dut.functional_compiler_options[:output_directory]}/**/*.PAT").each do |f|
            File.delete(f)
          end
          Dir.glob("#{dut.functional_compiler_options[:path]}/**/*.log").each do |f|
            File.delete(f)
          end
          # This compiler instance does not specify path but does specify a pinmap
          # The pinmap passed as an option should override $dut.pinmap
          dut.add_pattern_compiler(:bist, :ultraflex, dut.bist_compiler_options)
          # The pinmap passed to the compiler as an option overrode the one at $dut.pinmap
          dut.pinmap.should_not == dut.pattern_compilers[:bist].pinmap.to_s
          bist_pattern_count = Dir["#{Origen.root}/spec/patterns/atp/bist/*.atp*"].count
          Dir["#{Origen.root}/spec/patterns/atp/bist/*.atp*"].each do |f|
            atp = Pathname.new(f)
            next unless atp.extname == '.gz' || atp.extname == '.atp'
            # Ignore patterns that do not have 'prod' in the name
            next unless atp.basename.to_s.match(/prod/)
            dut.pattern_compilers[:bist].find_jobs(atp)
          end
          # Filtered one pattern
          dut.pattern_compilers[:bist].count.should == 3
          # Save the compiler queue to a pattern list file for diff or run later
          dut.pattern_compilers[:bist].to_list(name: 'bist_compile', force: true, output_directory: dut.bist_compiler_options[:output_directory])
          dut.pattern_compilers[:bist].run
          bist_pat_matches = Dir.glob("#{$dut.bist_compiler_options[:output_directory]}/**/*.PAT").count
          bist_pat_matches.should == bist_pattern_count - 1
          # Clean up patterns and log files from previous spec testing
          Dir.glob("#{$dut.bist_compiler_options[:output_directory]}/**/*.PAT").each do |f|
            File.delete(f)
          end
          dut.pattern_compilers[:bist].count.should == 0
        end

        it 'can compile a pattern list' do
          # Compile the patterns using the pattern list created earlier
          list = Pathname.new("#{dut.bist_compiler_options[:output_directory]}/bist_compile.list")
          dut.pattern_compilers[:bist].run(list, dut.bist_compiler_options)
          bist_pat_matches = Dir.glob("#{dut.bist_compiler_options[:output_directory]}/**/*.PAT").count
          # compiled patterns count should match what we had when we wrote out the pattern list
          bist_pat_matches.should == 3
        end
    end
    end
  end
end
