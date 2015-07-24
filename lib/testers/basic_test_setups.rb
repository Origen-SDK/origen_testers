module Testers
  # Including this module in a class will create a basic test program interface that
  # can generate programs for all ATE platforms supported by the Testers plugin.
  #
  # It provides a number of methods that can be called from a test program flow file
  # to do basic things like a functional test.
  #
  # @example How to setup and use
  #   # lib/myapp/program_interface.rb
  #   module MyApp
  #     class Interface
  #       include Testers::BasicTestSetups
  #     end
  #   end
  #
  #   # program/prb1.rb
  #   Flow.create interface: 'MyApp::Interface' do
  #
  #     functional :my_pattern_1, bin: 10
  #     functional :my_pattern_2, bin: 11
  #
  #   end
  module BasicTestSetups
    include Testers::ProgramGenerators

    # Execute a functional test
    #
    # @param [Symbol, String] name the name of the test.
    # @param [Hash] options the options to customize the test.
    # @option options [Integer] :bin The bin number
    # @option options [Integer] :sbin The soft bin number
    # @option options [String] :pattern The pattern name, if not specified the test
    #   name will be used
    # @option options [String] :pin_levels ('Lvl') The name of the pin levels
    # @option options [String] :time_set ('Tim') The name of the time set
    #
    # @see http://rgen.freescale.net/rgen/latest/guides/program/flowapi/ The options associated with the flow control API are fully supported
    #
    # @example Customizing a test from the flow
    #   functional :erase, pattern: 'erase_all_nosrc', sbin: 150
    #
    # @example Applying global customization from the interface
    #   include Testers::BasicTestSetups
    #
    #   def functional(name, options = {})
    #     # Apply custom defaults before calling
    #     options = {
    #       bin: 3,
    #       levels: 'nvm',
    #     }.merge(options)
    #     # Now call the generator
    #     super
    #   end
    #
    # @return [Hash] all generated components of the test will be returned. The key
    #   naming will depend on what platform the test has been generated for, but for
    #   example this will contain :flow_line, :test_instance and :patset objects in
    #   the case of an IG-XL-based platform.
    #
    # @example Adding a custom interpose function for J750
    #   include Testers::BasicTestSetups
    #
    #   # Override the default J750 test instance to add an interpose function
    #   def functional(name, options = {})
    #     components = super
    #     if tester.j750?
    #       components[:test_instance].post_test_func = 'delayedBinning'
    #     end
    #   end
    def functional(name, options = {})
      options = {
        pin_levels: 'Lvl',
        time_set:   'Tim'
      }.merge(options)
      pattern = extract_pattern(name, options)
      if tester.j750? || tester.j750_hpt? || tester.ultraflex?
        ins = test_instances.functional(name, options)
        pname = "#{pattern}_pset"
        pset = patsets.add(pname, [{ pattern: "#{pattern}.PAT" }])
        ins.pattern = pname
        line = flow.test(ins, options)
        { test_instance: ins, flow_line: line, patset: pset }
      elsif tester.v93k?
        tm = test_methods.ac_tml.ac_test.functional_test
        ts = test_suites.run(name, options)
        ts.test_method = tm
        ts.pattern = pattern
        node = flow.test(ts, options)
        { test_method: tm, test_suite: ts, node: node }
      else
        fail "Unsupported tester: #{tester.class}"
      end
    end

    # Extract the pattern name from the given options, falling back to the given
    # test name if a :pattern option is not present.
    #
    # It will also strip any extension if one is present.
    def extract_pattern(name, options = {})
      p = options[:pattern] || name
      p = p.to_s.sub(/\..*$/, '')
      p
    end
  end
end
