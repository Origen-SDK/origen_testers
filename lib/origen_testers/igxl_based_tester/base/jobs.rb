module OrigenTesters
  module IGXLBasedTester
    class Base
      class Jobs
        include ::OrigenTesters::Generator
        attr_accessor :jobs

        OUTPUT_PREFIX = nil
        OUTPUT_POSTFIX = nil

        def initialize # :nodoc:
          @jobs = {}
        end

        def add(jname, options = {})
          @jobs.key?(jname) ? @jobs[jname].add_job_info(jname, options) : @jobs[jname] = platform::Job.new(jname, options)
          @jobs[jname]
        end

        def finalize(options = {})
          @jobs.each do |_key, job|
            job.pinmap         = job.pinmap.flatten.uniq
            job.instances      = job.instances.flatten.uniq
            job.flows          = job.flows.flatten.uniq
            job.ac_specs       = job.ac_specs.flatten.uniq
            job.dc_specs       = job.dc_specs.flatten.uniq
            job.patsets        = job.patsets.flatten.uniq
            job.patgroups      = job.patgroups.flatten.uniq
            job.bintables      = job.bintables.flatten.uniq
            job.cz             = job.cz.flatten.uniq
            job.test_procs     = job.test_procs.flatten.uniq
            job.mix_sig_timing = job.mix_sig_timing.flatten.uniq
            job.wave_defs      = job.wave_defs.flatten.uniq
            job.psets          = job.psets.flatten.uniq
            job.signals        = job.signals.flatten.uniq
            job.port_map       = job.port_map.flatten.uniq
            job.fract_bus      = job.fract_bus.flatten.uniq
            job.concurrent_seq = job.concurrent_seq.flatten.uniq
          end
        end
      end
    end
  end
end
