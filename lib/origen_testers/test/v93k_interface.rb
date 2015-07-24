module Testers
  module Test
    class V93KInterface
      include Testers::V93K::Generator

      # Options passed to Flow.create and Library.create will be passed in here, use as
      # desired to configure your interface
      def initialize(options = {})
      end

      def log(msg)
        flow.print_to_datalog(msg)
      end

      def func(name, options = {})
        options = {
          duration: :static
        }.merge(options)

        block_loop(name, options) do |block, i, group|
          tm = test_methods.ac_tml.ac_test.functional_test
          ts = test_suites.run(name, options)
          ts.test_method = tm
          ts.levels = options.delete(:pin_levels) if options[:pin_levels]
          if group
            ts.pattern = "#{name}_b#{i}"
          else
            ts.pattern = name.to_s
            #    if options[:cz_setup]
            #      flow.cz(ins, options[:cz_setup], options)
            #    else
            #    end
          end
          flow.test ts, options
        end
      end

      def meas(name, options = {})
        options = {
          duration: :static
        }.merge(options)

        name = "meas_#{name}" unless name.to_s =~ /meas/

        tm = test_methods.dc_tml.dc_test.general_pmu
        ts = test_suites.run(name, options)
        ts.test_method = tm
        ts.levels = options.delete(:pin_levels) if options[:pin_levels]
        ts.lo_limit = options[:lo_limit] if options[:lo_limit]
        ts.hi_limit = options[:hi_limit] if options[:hi_limit]
        ts.pattern = name.to_s
        # if options[:cz_setup]
        #  flow.cz(ins, options[:cz_setup], options)
        # else
        #  use_limit_params = [:lo_limit, :hi_limit, :scale, :units] # define options to strip for flow.test
        #  options_use_limit = options.dup                           # duplicate, as modifying options directly, even an assigned copy modifies original
        #  flow.test(ins, options.reject! { |k, _| use_limit_params.include? k })    # set up test skipping use-limit options
        #  flow.use_limit(name, options_use_limit) if options_use_limit[:hi_limit] || options_use_limit[:lo_limit]  # Only use use-limit if limits present in flow
        # end
        flow.test ts, options
      end

      def group(name, options = {})
        flow.group name, options do |group|
          yield group
        end
      end

      def block_loop(name, options)
        if options[:by_block]
          flow.group name, options do |group|
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
        func('por_ins', options)
      end

      def para(name, options = {})
        # print "UltraFLEX Parametric Test not yet supported for UltraFLEX!\n"
      end

      # OR 2 IDS together into 1 flag
      # def or_ids(options = {})
      #  flow.or_flags(options[:id1], options[:id2], options)
      # end

      def nop(options = {})
        # flow.nop options
      end

      def mto_memory(name, options = {})
        # Seriously?!
      end

      # OR 2 IDS together into 1 flag
      def or_ids(options = {})
        # Eh?
      end

      def bin(number, options = {})
        flow.good_bin(number, bin_desc: options[:description])
      end
    end
  end
end
