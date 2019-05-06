require 'spec_helper'
require "#{Origen.app.root}/lib/origen_testers/test/dummy_decompiler"
require_relative 'decompiler/common'

require_relative 'decompiler/matchers'
require_relative 'decompiler/pattern'
require_relative 'decompiler/decompiler_api'
require_relative 'decompiler/topmost_methods'
require_relative 'decompiler/platform_interface/platform_interface'
Dir["#{Origen.app!.root}/spec/decompiler/platforms/**/*.rb"].each do |f|
  require f
end

module OrigenTesters
  module Decompiler
    module RSpec
      @platforms = {
        j750: J750,
        v93k: V93K,
      }
      @platforms.each do |name, mod|
        self.class_eval do
          define_singleton_method(name) do
            mod
          end
        end
      end
      
      def self.platforms
        @platforms
      end

      @defs = {

        # Generic name to generate 'missing pattern'/'no source' error.
        # Note: this contains a valid extension, but an invalid path
        missing_atp_src: j750.approved_dir.join('no_pattern.atp').to_s,
        
        # Generic name to generate 'unknown extension' errors.
        # This pattern doesn't exist, but has an invalid extension name as well.
        # Extension name will be handled first, as it fails to find a suitable decompiler.
        unknown_src: j750.approved_dir.join('no_pattern.unknown').to_s,
        
        dummy_mods: OrigenTesters::Test::Decompiler::Dummy,
        dummy_mod_with_decompiler: OrigenTesters::Test::Decompiler::DummyWithDecompiler,
        dummy_mod_incomplete_decompiler: OrigenTesters::Test::Decompiler::DummyWithDecompilerMissingMethod,
        dummy_pattern: OrigenTesters::Test::Decompiler::Dummy::Pattern,
        
        dut_pins: {tclk:1, tdi:1, tdo:1, tms: 1},
        dut2_pins: {
          nvm_reset: 1,
          nvm_clk: 1,
          nvm_clk_mux: 1,
          porta: 8,
          portb: 8,
          nvm_invoke: 1,
          nvm_done: 1,
          nvm_fail: 1,
          nvm_alvtst: 1,
          nvm_ahvtst: 1,
          nvm_dtst: 1,
          tclk: 1,
          trst: 1
        },
        
        direct_source: [
          'import tset tp0;',
          'svm_only_file = no;',
          'opcode_mode = extended;',
          'compressed = yes;',
          '',
          'vector ($tset, tclk, tdi, tdo, tms)',
          '{',
          'start_label pattern_st:',
          'repeat 11316 > tp0 X X X X ;',
          'end_module   > tp0 X X X X ;',
          '}',
        ].join("\n"),
        
        execution_pattern: "#{Origen.app!.root}/pattern/decompile.rb",
      }
      @defs[:delay_pattern_pins] = @defs[:dut_pins]
      @defs[:default_target_pins] = @defs[:dut_pins]
      @defs[:workout_pattern_pins] = @defs[:dut2_pins]
      @defs[:legacy_target_pins] = @defs[:dut2_pins]
            
      def self.defs
        @defs
      end

      def self.new_dummy_pattern(*args)
        # Use the dummy decompiler implementation from origen_testers/test/dummy
        dummy_pattern.new(*args)
      end

      def self.method_missing(m, *args, &block)
        if @defs.key?(m)
          define_singleton_method(m) { @defs[m] }
          return @defs[m]
        end
        super
      end
      
    end
  end
end

describe OrigenTesters::Decompiler do
  let(:rspec) { OrigenTesters::Decompiler::RSpec }
  let(:defs) { rspec.defs }
  let(:dummy_mods) { defs[:dummy_mods] }
  let(:dummy_mod) { dummy_mods }
  
  OrigenTesters::Decompiler::RSpec.platforms.each do |name, platform|
    include_examples(:platform_interface, platform)
  end

  include_examples(:decompiler_api, {})
  include_examples(:decompiled_pattern, {})
  include_examples(:decompiler_top_methods, {})
end

