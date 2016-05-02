module OrigenTesters
  module IGXLBasedTester
    class Base
      class Job
        attr_accessor :name
        attr_accessor :pinmap
        attr_accessor :instances
        attr_accessor :flows
        attr_accessor :ac_specs
        attr_accessor :dc_specs
        attr_accessor :patsets
        attr_accessor :patgroups
        attr_accessor :bintables
        attr_accessor :cz
        attr_accessor :test_procs
        attr_accessor :mix_sig_timing
        attr_accessor :wave_defs
        attr_accessor :psets
        attr_accessor :signals
        attr_accessor :port_map
        attr_accessor :fract_bus
        attr_accessor :concurrent_seq
        attr_accessor :comment

        def initialize(jname, options = {}) # :nodoc:
          @name = jname
          options[:pinmap] ? @pinmap         = [options[:pinmap]] : @pinmap         = []
          options[:instances] ? @instances      = [options[:instances]] : @instances      = []
          options[:flows] ? @flows          = [options[:flows]] : @flows          = []
          options[:ac_specs] ? @ac_specs       = [options[:ac_specs]] : @ac_specs       = []
          options[:dc_specs] ? @dc_specs       = [options[:dc_specs]] : @dc_specs       = []
          options[:patsets] ? @patsets        = [options[:patsets]] : @patsets        = []
          options[:patgroups] ? @patgroups      = [options[:patgroups]] : @patgroups      = []
          options[:bintables] ? @bintables      = [options[:bintables]] : @bintables      = []
          options[:cz] ? @cz             = [options[:cz]] : @cz             = []
          options[:test_procs] ? @test_procs     = [options[:test_procs]] : @test_procs     = []
          options[:mix_sig_timing] ? @mix_sig_timing = [options[:mix_sig_timing]] : @mix_sig_timing = []
          options[:wave_defs] ? @wave_defs      = [options[:wave_defs]] : @wave_defs      = []
          options[:psets] ? @psets          = [options[:psets]] : @psets          = []
          options[:signals] ? @signals        = [options[:signals]] : @signals        = []
          options[:port_map] ? @port_map       = [options[:port_map]] : @port_map       = []
          options[:fract_bus] ? @fract_bus      = [options[:fract_bus]] : @fract_bus      = []
          options[:concurrent_seq] ? @concurrent_seq = [options[:concurrent_seq]] : @concurrent_seq = []
          options[:comment] ? @comment        = options[:instances] : @comment        = nil
        end

        # Assigns job information for the given object
        def add_job_info(jname, options = {})
          @pinmap.push(options[:pinmap]) if options[:pinmap]
          @instances.push(options[:instances]) if options[:instances]
          @flows.push(options[:flows]) if options[:flows]
          @ac_specs.push(options[:ac_specs]) if options[:ac_specs]
          @dc_specs.push(options[:dc_specs]) if options[:dc_specs]
          @patsets.push(options[:patsets]) if options[:patsets]
          @patgroups.push(options[:patgroups]) if options[:patgroups]
          @bintables.push(options[:bintables]) if options[:bintables]
          @cz.push(options[:cz]) if options[:cz]
          @test_procs.push(options[:test_procs]) if options[:test_procs]
          @mix_sig_timing.push(options[:mix_sig_timing]) if options[:mix_sig_timing]
          @wave_defs.push(options[:wave_defs]) if options[:wave_defs]
          @psets.push(options[:psets]) if options[:psets]
          @signals.push(options[:signals]) if options[:signals]
          @port_map.push(options[:port_map]) if options[:port_map]
          @fract_bus.push(options[:fract_bus]) if options[:fract_bus]
          @concurrent_seq.push(options[:concurrent_seq]) if options[:concurrent_seq]
          @comment = options[:instances] if options[:instances]
        end

        def platform
          Origen.interface.platform
        end
      end
    end
  end
end
