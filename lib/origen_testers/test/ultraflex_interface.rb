module Testers
  module Test
    class UltraFLEXInterface
      include Testers::UltraFLEX::Generator

      # Options passed to Flow.create and Library.create will be passed in here, use as
      # desired to configure your interface
      def initialize(options = {})
      end

      def log(msg)
        flow.logprint(msg)
      end

      def func(name, options = {})
        options = {
          duration: :static
        }.merge(options)

        block_loop(name, options) do |block, i, group|
          ins = test_instances.functional(name)
          ins.set_wait_flags(:a) if options[:duration] == :dynamic
          ins.pin_levels = options.delete(:pin_levels) if options[:pin_levels]
          if group
            pname = "#{name}_b#{i}_pset"
            patsets.add(pname, [{ pattern: "#{name}_b#{i}.PAT" },
                                { pattern: 'nvm_global_subs.PAT', start_label: 'subr' }])
            ins.pattern = pname
            flow.test(group, options) if i == 0
          else
            pname = "#{name}_pset"
            patsets.add(pname, [{ pattern: "#{name}.PAT" },
                                { pattern: 'nvm_global_subs.PAT', start_label: 'subr' }])
            ins.pattern = pname
            if options[:cz_setup]
              flow.cz(ins, options[:cz_setup], options)
            else
              flow.test(ins, options)
            end
          end
        end
      end

      def meas(name, options = {})
        options = {
          duration: :static
        }.merge(options)

        name = "meas_#{name}" unless name.to_s =~ /meas/

        ins = test_instances.functional(name)
        ins.set_wait_flags(:a) if options[:duration] == :dynamic
        ins.pin_levels = options.delete(:pin_levels) if options[:pin_levels]

        pname = "#{name}_pset"
        patsets.add(pname, [{ pattern: "#{name}.PAT" },
                            { pattern: 'nvm_global_subs.PAT', start_label: 'subr' }])
        ins.pattern = pname
        if options[:cz_setup]
          flow.cz(ins, options[:cz_setup], options)
        else
          use_limit_params = [:lo_limit, :hi_limit, :scale, :units] # define options to strip for flow.test
          options_use_limit = options.dup                           # duplicate, as modifying options directly, even an assigned copy modifies original
          flow.test(ins, options.reject! { |k, _| use_limit_params.include? k })    # set up test skipping use-limit options
          flow.use_limit(name, options_use_limit) if options_use_limit[:hi_limit] || options_use_limit[:lo_limit]  # Only use use-limit if limits present in flow
        end
      end

      def block_loop(name, options)
        if options[:by_block]
          test_instances.group do |group|
            group.name = name
            $dut.blocks.each_with_index do |block, i|
              yield block, i, group
            end
          end
        else
          yield
        end
      end

      def por(options = {})
        options = {
          instance_not_available: true
        }.merge(options)
        flow.test('por_ins', options)
      end

      def para(name, options = {})
        print "UltraFLEX Parametric Test not yet supported for UltraFlex!\n"
      end

      # OR 2 IDS together into 1 flag
      def or_ids(options = {})
        flow.or_flags(options[:id1], options[:id2], options)
      end

      def nop(options = {})
        flow.nop options
      end

      def mto_memory(args)
        # DO NOTHING, NOT YET SUPPORTED IN ULTRAFLEX
      end

      def bin(number, options = {})
      end
    end
  end
end
