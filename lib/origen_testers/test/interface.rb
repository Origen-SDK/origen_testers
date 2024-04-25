module OrigenTesters
  module Test
    class Interface
      include OrigenTesters::ProgramGenerators
      include OrigenTesters::Charz

      attr_accessor :include_additional_prb2_test
      attr_reader :environment

      # Options passed to Flow.create and Library.create will be passed in here, use as
      # desired to configure your interface
      def initialize(options = {})
        @environment = options[:environment]
        add_charz
        add_my_tml if tester.v93k?
      end

      def add_my_tml
        add_tml :my_hash_tml,
                class_name:   'MyTmlHashNamespace',

                # Here is a test definition.
                # The identifier should be lower-cased and underscored, in-keeping with Ruby naming conventions.
                # By default the class name will be the camel-cased version of this identifier, so 'myTest' in
                # this case.
                my_hash_test: {
                  # [OPTIONAL] The C++ test method class name can be overridden from the default like this:
                  class_name:             'MyHashExampleClass',
                  # [OPTIONAL] If the test method does not require a definition in the testmethodlimits section
                  #    of the .tf file, you can suppress like this:
                  # render_limits_in_file: false,
                  # Parameters can be defined with an underscored symbol as the name, this can be used
                  # if the C++ implementation follows the standard V93K convention of calling the attribute
                  # the camel cased version, starting with a lower-cased letter, i.e. 'testerState' in this
                  # first example.
                  # The attribute definition has two required parameters, the type and the default value.
                  # The type can be :string, :current, :voltage, :time, :frequency, integer, :double or :boolean
                  pin_list:               [:string, ''],
                  samples:                [:integer, 1],
                  precharge_voltage:      [:voltage, 0],
                  settling_time:          [:time, 0],
                  # An optional parameter that sets the limits name in the 'testmethodlimits' section
                  # of the generated .tf file.  Defaults to 'Functional' if not provided.
                  test_name:              [:string, 'HashExample'],
                  # An optional 3rd parameter can be supplied to provide an array of allowed values. If supplied,
                  # Origen will raise an error upon an attempt to set it to an unlisted value.
                  tester_state:           [:string, 'CONNECTED', %w(CONNECTED UNCHANGED DISCONNECTED)],
                  force_mode:             [:string, 'VOLT', %w(VOLT CURR)],
                  # The name of another parameter can be supplied as the type argument, meaning that the type
                  # here will be either :current or :voltage depending on the value of :force_mode
                  # force_value: [:force_mode, 3800.mV],
                  # In cases where the C++ library has deviated from standard attribute naming conventions
                  # (camel-cased with lower cased first character), the absolute attribute name can be given
                  # as a string.
                  # The Origen accessor for these will be the underscored version, with '.' characters
                  # converted to underscores e.g. tm.an_unusual_name
                  'hashParameter':        [{ param_name0: [:string, 'NO'], param_name1: [:integer, 0] }],
                  'hashParameter2':       [{ param_name0: [:string, 'NO'], param_name1: [:integer, 0] }],
                  'nestedHashParameter':  [{
                    param_name0:        [:string, ''],
                    param_list_strings: [:list_strings, %w(E1 E2)],
                    param_list_classes: [:list_classes, %w(E1 E2)],
                    param_name1:        [{
                      param_name0:        [:integer, 0],
                      param_list_strings: [:list_strings, %w(E1 E2)],
                      param_list_classes: [:list_classes, %w(E1 E2)]
                    }]
                  }],
                  'nestedHashParameter2': [{
                    param_name0: [:string, ''],
                    param_name1: [{
                      param_name0: [:integer, 0]
                    }]
                  }]
                }
      end

      def add_charz
        add_charz_routine :routine1 do |routine|
          routine.name = '_cz__rt1'
        end
        add_charz_routine :routine2 do |routine|
          routine.name = '_cz__rt2'
        end
        add_charz_routine :routine3 do |routine|
          routine.name = '_cz__rt3'
        end
        add_charz_routine :routine4 do |routine|
          routine.name = '_cz__rt4'
        end
        add_charz_routine :routine5 do |routine|
          routine.name = '_cz__rt5'
        end
        add_charz_routine :routine6 do |routine|
          routine.name = '_cz__rt6'
        end
        add_charz_profile :cz do |profile|
          profile.routines = [:routine3]
        end
        add_charz_profile :cz_only do |profile|
          profile.charz_only = true
          profile.routines = [:routine1]
        end
        add_charz_profile :simple_gates do |profile|
          profile.flags = :my_flag
          profile.enables = :my_enable
          profile.routines = [:routine1]
        end
        add_charz_profile :complex_gates do |profile|
          profile.flags = { ['$MyFlag1'] => [:routine1, :routine2], ['$MyFlag2'] => [:routine3], '$MyFlag3' => :routine4 }
          profile.enables = { ['$MyEnable1'] => [:routine1], ['$MyEnable2'] => [:routine2, :routine3], '$MyEnable3' => :routine5 }
          profile.routines = [:routine1, :routine2, :routine3, :routine4, :routine5, :routine6]
        end

        add_charz_profile :simple_anded_flags do |profile|
          profile.and_flags = true
          profile.routines = [:routine1]
        end

        add_charz_profile :simple_anded_enables do |profile|
          profile.and_enables = true
          profile.routines = [:routine1]
        end

        add_charz_profile :complex_anded_flags do |profile|
          profile.and_flags = true
          profile.enables = :my_enable
          profile.routines = [:routine1]
        end

        add_charz_profile :complex_anded_enables do |profile|
          profile.and_enables = true
          profile.flags = :my_flag
          profile.routines = [:routine1]
        end
      end

      # Test that the block form of flow control methods like this can
      # be overridden by an interface
      def if_job(*jobs)
        jobs = jobs.flatten
        jobs.delete(:prb9)
        super
      end
      alias_method :if_jobs, :if_job

      def log(msg)
        if tester.j750? || tester.uflex?
          flow.logprint(msg)
        else
          flow.log(msg)
        end
      end

      def func(name, options = {})
        options = {
          duration: :static
        }.merge(options)
        number = options[:number]

        if tester.j750? || tester.uflex?
          block_loop(name, options) do |block, i, group|
            options[:number] = number + i if number && i
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

        elsif tester.v93k?
          block_loop(name, options) do |block, i|
            options[:number] = number + i if number && i
            tm = test_methods.ac_tml.ac_test.functional_test
            ts = test_suites.run(name, options)
            ts.test_method = tm
            if tester.smt8?
              ts.spec = options.delete(:pin_levels) if options[:pin_levels]
              ts.spec ||= 'specs.Nominal'
            else
              ts.levels = options.delete(:pin_levels) if options[:pin_levels]
            end
            if block
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
      end

      def func_with_charz(name, options = {})
        options = {
          duration: :static
        }.merge(options)

        if tester.v93k?
          if tester.smt7?
            tm = test_methods.ac_tml.ac_test.functional_test
            ts = test_suites.run(name, options)
            ts.test_method = tm
            ts.pattern = 'charz_example'

            test_level_charz = false
            if options[:charz]
              charz_on(*options[:charz])
              test_level_charz = true
            end

            unless charz_only? && !options[:charz_test]
              options[:parent_test_name] = name
              set_conditional_charz_id(options)
              flow.test ts, options
            end

            unless options[:charz_test]
              insert_charz_tests(options.merge(parent_test_name: name, charz_test: true)) do |options|
                charz_name = :"#{name}_#{charz_routines[options[:current_routine]].name}"
                func_with_charz(charz_name, options)
              end
            end

            charz_off if test_level_charz
          else
            fail 'Only SMT7 is Implemented for Charz'
          end
        else
          fail "Tester #{tester.name} Not Yet Implemented for Charz"
        end
      end

      def func_with_comment(name, options = {})
        if tester.v93k?
          options = {
            duration: :static
          }.merge(options)
          number = options[:number]

          block_loop(name, options) do |block, i|
            options[:number] = number + i if number && i
            tm = test_methods.ac_tml.ac_test.functional_test
            ts = test_suites.run(name, options)
            ts.test_method = tm
            ts.levels = options.delete(:pin_levels) if options[:pin_levels]
            ts.comment = options.delete(:comment) || flow.active_description
            if block
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
        else
          func(name, options)
        end
      end

      def my_hash_test(name, options = {})
        number = options[:number]

        if tester.v93k? && tester.smt8?
          block_loop(name, options) do |block, i|
            options[:number] = number + i if number && i
            tm = test_methods.my_hash_tml.my_hash_test
            tm.hashParameter = {
              param1: {}
            }
            tm.nestedHashParameter = {
              my_param_name0: {
                param_name0: 'hello',
                param_name1: {
                  my_param_name1: {
                    param_name0: 1
                  },
                  my_param_name2: {
                    param_name0: 2
                  },
                  my_param_name3: {
                    param_name0: 3
                  }
                }
              }
            }
            tm.nestedHashParameter2 = {
              my_param_name4: {
                param_name0: 'goodbye'
              },
              my_param_name5: {
                param_name0: 'goodbye forever'
              }
            }
            ts = test_suites.run(name, options)
            ts.test_method = tm
            ts.spec = options.delete(:pin_levels) if options[:pin_levels]
            ts.spec ||= 'specs.Nominal'
            flow.test ts, options
          end
        end
      end

      def my_override_spec_test(name, options = {})
        number = options[:number]

        if tester.v93k? && tester.smt8?
          tm = test_methods.ac_tml.ac_test.functional_test
          ts = test_suites.run(name, options)
          ts.test_method = tm
          ts.spec = options.delete(:pin_levels) if options[:pin_levels]
          ts.spec ||= 'specs.Nominal'
          ts.pattern = 'pat1'
          ts.burst = 'sequence1'
          ts.spec_path = 'myCustomSpecPath'
          ts.seq_path  = 'myCustomSeqPath'
          ts.spec_namespace = 'myCustomSpecNamespace'
          ts.seq_namespace  = 'myCustomSeqNamespace'
          flow.test ts, options
        end
      end

      def block_loop(name, options)
        if options[:by_block]
          if tester.j750? || tester.uflex?
            test_instances.group do |group|
              group.name = name
              $dut.blocks.each_with_index do |block, i|
                yield block, i, group
              end
            end
          elsif tester.v93k?
            flow.group name, options do
              $dut.blocks.each_with_index do |block, i|
                yield block, i
              end
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
        if tester.j750? || tester.uflex?
          flow.test('por_ins', options)
        else
          func('por_ins', options)
        end
      end

      def para(name, options = {})
        options = {
          high_voltage: false
        }.merge(options)

        if tester.j750?
          if options.delete(:high_voltage)
            ins = test_instances.bpmu(name)
          else
            ins = test_instances.ppmu(name)
          end
          ins.dc_category = 'NVM_PARA'
          flow.test(ins, options)
          patsets.add("#{name}_pset", pattern: "#{name}.PAT")
        end
      end

      # OR 2 IDS together into 1 flag
      def or_ids(options = {})
        flow.or_flags(options[:id1], options[:id2], options)
      end

      def nop(options = {})
        flow.nop options
      end

      def mto_memory(name, options = {})
        options = {
          duration: :static
        }.merge(options)

        if tester.j750?
          block_loop(name, options) do |block, i, group|
            ins = test_instances.mto_memory(name)
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
      end

      def meas_multi_limits(name, options = {})
        options = {
          duration: :static
        }.merge(options)

        name = "measmulti_#{name}" unless name.to_s =~ /measmulti/

        if tester.uflex?
          ins = test_instances.functional(name)
          ins.set_wait_flags(:a) if options[:duration] == :dynamic
          ins.pin_levels = options.delete(:pin_levels) if options[:pin_levels]
          ins.defer_limits = options[:defer_limits]

          # some made up sub test limits
          options[:sub_tests] = [sub_test('limit1', lo: 0, hi: 7), sub_test('limit2', lo: 3, hi: 8)]

          pname = "#{name}_pset"
          patsets.add(pname, [{ pattern: "#{name}.PAT" },
                              { pattern: 'nvm_global_subs.PAT', start_label: 'subr' }])
          ins.pattern = pname

          flow.test(ins, options)
        end
      end

      def meas(name, options = {})
        options = {
          duration: :static
        }.merge(options)

        name = "meas_#{name}" unless name.to_s =~ /meas/

        if tester.j750? || tester.uflex?
          if tester.uflex?
            ins = test_instances.functional(name)
            ins.set_wait_flags(:a) if options[:duration] == :dynamic
            ins.pin_levels = options.delete(:pin_levels) if options[:pin_levels]
            ins.lo_limit = options[:lo_limit]
            ins.hi_limit = options[:hi_limit]
            ins.scale = options[:scale]
            ins.units = options[:units]
            ins.defer_limits = options[:defer_limits]
          else
            if options[:pins] == :hi_v
              ins = test_instances.board_pmu(name)
            elsif options[:pins] == :power
              ins = test_instances.powersupply(name)
            else
              ins = test_instances.pin_pmu(name)
            end
            ins.set_wait_flags(:a) if options[:duration] == :dynamic
            ins.pin_levels = options.delete(:pin_levels) if options[:pin_levels]
            ins.lo_limit = options[:lo_limit]
            ins.hi_limit = options[:hi_limit]
          end

          pname = "#{name}_pset"
          patsets.add(pname, [{ pattern: "#{name}.PAT" },
                              { pattern: 'nvm_global_subs.PAT', start_label: 'subr' }])
          ins.pattern = pname
          if options[:cz_setup]
            flow.cz(ins, options[:cz_setup], options)
          else
            flow.test(ins, options)
          end

        elsif tester.v93k?
          tm = test_methods.dc_tml.dc_test.general_pmu
          ts = test_suites.run(name, options)
          ts.test_method = tm
          if tester.smt8?
            ts.spec = options.delete(:pin_levels) if options[:pin_levels]
            ts.spec ||= 'specs.Nominal'
          else
            ts.levels = options.delete(:pin_levels) if options[:pin_levels]
          end
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

        ####################################################
        #######  UltraFLEX Pinmap Stuff ####################
        ####################################################

        # Assign relevant pins for pinmap sheet generation
        def pinmap(name, options = {})
          pinmap = pinmaps("#{name}")
          Origen.top_level.add_pin_group :JTAG, :tdi, :tdo, :tms
          Origen.top_level.power_pin_groups.keys.each do |grp_key|
            pinmap.add_power_pin(grp_key, type: 'Power', comment: "# #{grp_key}")
          end
          Origen.top_level.virtual_pins.keys.each do |util_pin|
            upin = Origen.top_level.virtual_pins(util_pin)
            case upin.type
            when :virtual_pin
              pinmap.add_utility_pin(upin.name, type: 'Utility', comment: "# #{util_pin}")
            when :ate_ch
              pinmap.add_utility_pin(upin.name, type: 'I/O', comment: "# #{util_pin}")
            end
          end
          Origen.top_level.pin.keys.each do |pkey|
            pinmap.add_pin(Origen.top_level.pin(pkey).name, type: 'I/O', comment: "# #{pkey}")
          end
          Origen.top_level.pin_groups.keys.sort.each do |gkey|
            # Do not include pins that are aliased to themselves
            Origen.top_level.pin(gkey).each do |pin|
              pinmap.add_group_pin(gkey, Origen.top_level.pin(pin.id).name, type: 'I/O', comment: "# #{gkey}")
            end
          end
        end

        # Assign relevant edges in preparation for edgeset/timeset sheet generation
        def edge(category, pin, options = {})
          options = {
            d_src:   'PAT',     # source of the channel drive data (e.g. pattern, drive_hi, drive_lo, etc.)
            d_fmt:   'NR',      # drive data format (NR, RL, RH, etc.)
            d0_edge: '',        # time at which the input drive is turned on
            d1_edge: '',        # time of the initial data drive edge
            d2_edge: '',        # time of the return format data drive edge
            d3_edge: '',        # time at which the input drive is turned off
            c_mode:  'Edge',    # output compare mode
            c1_edge: '',        # time of the initial output compare edge
            c2_edge: '',        # time of the final output compare edge (window compare)
            t_res:   'Machine', # timing resolution (possibly ATE-specific)
            clk_per: ''         # clock period equation - for use with MCG
          }.merge(options)

          @edge_collection = edges
          @edge_collection.add(category, pin, options)
        end

        def edge_collection
          @edge_collection
        end

        def edgeset(sheet_name, options = {})
          options = {
            edgeset: :es_default,
            period:  'cycle',        # tester cycle period
            t_mode:  'Machine'       # edgeset timing mode (possibly ATE-specific)
          }.merge(options)
          edgeset = options.delete(:edgeset)
          pin = options.delete(:pin)
          edge = options.delete(:edge)

          @edgeset = edgesets(sheet_name, options)
          @edgeset.add(edgeset, pin, edge, options)
          collect_ac_specs(@edgeset.es[edgeset].spec_sheet, edge)
        end

        def timeset(sheet_name, options = {})
          options = {
            timeset:   :default,
            master_ts: :default
          }.merge(options)
          timeset = options.delete(:timeset)
          pin = options.delete(:pin)
          eset = options.delete(:eset)

          @timeset = timesets(sheet_name, options)
          @timeset.add(timeset, pin, eset, options)
        end

        def ac_specset(sheet_name, expression, options = {})
          options = {
            specset: :default,
            nom:     { typ: nil }
          }.merge(options)

          ss = ac_specsets(sheet_name)
          add_ac_specs(ss, expression, options)
        end

        # Collects AC Spec object(s) from the given expression and adds them to the given Specset
        def collect_ac_specs(ssname, edge, options = {})
          options = {
            nom: { typ: nil }
          }.merge(options)

          # Create a Specsets object from the UFlex program generator API
          ss = ac_specsets(ssname.to_sym)
          add_ac_specs(ss, edge.clk_per, options)
          add_ac_specs(ss, edge.d0_edge, options)
          add_ac_specs(ss, edge.d1_edge, options)
          add_ac_specs(ss, edge.d2_edge, options)
          add_ac_specs(ss, edge.d3_edge, options)
          add_ac_specs(ss, edge.c1_edge, options)
          add_ac_specs(ss, edge.c2_edge, options)
        end

        # Adds new AC Spec object(s) to the given Specset
        def add_ac_specs(ss, expression, options = {})
          options = {
            specset: :default
          }.merge(options)

          return unless expression.is_a? String

          # collect all variable names within the expression
          vars = expression.scan(/[a-zA-Z]\w+/).map(&:to_sym)
          vars.each do |var|
            next if var =~ /^(d0_edge|d1_edge|d2_edge|d3_edge|c1_edge|c2_edge)$/
            # The substitutions below are used for backward compatibility
            next if var =~ /^(d_on|d_data|d_ret|d_off|c_open|c_close)$/
            next if var =~ /^(nS|uS|mS|S)$/i
            next if ss.ac_specsets.key?(options[:specset]) && ss.ac_specsets[options[:specset]].include?(var)

            ss.add(var, options)
          end
        end

        # Assign relevant power supply levels in preparation for levelset sheet generation
        def pwr_level(category, options = {})
          options = {
            vmain: 1.8,              # Main supply voltage
            valt:  1.8,              # Alternate supply voltage
            ifold: 1,                # Supply clamp current
            delay: 0                 # Supply power-up delay
          }.merge(options)

          @level_collection = levels
          @level_collection.add_power_level(category, options)
        end

        # Assign relevant single-ended pin levels in preparation for levelset sheet generation
        def pin_level_se(category, options = {})
          options = {
            vil:       0,            # Input drive low
            vih:       1.8,            # Input drive high
            vol:       1.0,            # Output compare low
            voh:       0.8,            # Output compare high
            vcl:       -1,            # Voltage clamp low
            vch:       2.5,            # Voltage clamp high
            vt:        0.9,            # Termination voltage
            voutlotyp: 0,            #
            vouthityp: 0,            #
            dmode:     'Largeswing-VT' # Driver mode
          }.merge(options)

          @level_collection = levels
          @level_collection.add_se_pin_level(category, options)
        end

        def level_collection
          @level_collection
        end

        def levelset(sheet_name, options = {})
          pin = options.delete(:pin)
          level = options.delete(:level)

          @levelset = levelsets(sheet_name)
          @levelset.add(sheet_name, pin, level, options)
          collect_dc_specs(@levelset.spec_sheet, level)
        end

        def dc_specset(sheet_name, expression, options = {})
          options = {
            min: { min:  nil },
            nom: { typ:  nil },
            max: { max:  nil }
          }.merge(options)

          ss = dc_specsets(sheet_name.to_sym)
          add_dc_specs(ss, expression, options)
        end

        # Collects DC Spec object(s) from the given expression and adds them to the given Specset
        def collect_dc_specs(ssname, level, options = {})
          options = {
            nom: { typ:  nil },
            min: { min:  nil },
            max: { max:  nil }
          }.merge(options)

          # Create a Specsets object from the UFlex program generator API
          ss = dc_specsets(ssname.to_sym)
          if level.respond_to?(:vmain)
            add_dc_specs(ss, level.vmain, options)
            add_dc_specs(ss, level.valt, options)
            add_dc_specs(ss, level.ifold, options)
          elsif level.respond_to?(:vil)
            add_dc_specs(ss, level.vil, options)
            add_dc_specs(ss, level.vih, options)
            add_dc_specs(ss, level.vol, options)
            add_dc_specs(ss, level.voh, options)
            add_dc_specs(ss, level.vcl, options)
            add_dc_specs(ss, level.vch, options)
            add_dc_specs(ss, level.vt, options)
            add_dc_specs(ss, level.voutlotyp, options)
            add_dc_specs(ss, level.vouthityp, options)
          end
        end

        # Adds new DC Spec object(s) to the given Specset
        def add_dc_specs(ss, expression, options = {})
          options = {
            specset: :default
          }.merge(options)

          return unless expression.is_a? String

          vars = expression.scan(/[a-zA-Z]\w+/).map(&:to_sym)
          vars.each do |var|
            next if var =~ /^(nA|uA|mA|A|nV|uV|mV|V)$/i

            ss.add(var, options)
          end
        end

        def global_spec(var, options = {})
          options = {
            job:     nil,
            value:   nil,
            comment: nil
          }.merge(options)

          global_specs('SpecsGlobal').add(var, job: options[:job], value: options[:value], comment: options[:comment])
        end

        def job_def(jname, options = {})
          options = {
            pinmap:         pinmap_sheets.map { |k, v| v.filename.gsub(/\.txt$/, '') },
            instances:      test_instance_sheets.map { |k, v| v.filename.gsub(/\.txt$/, '') },
            flows:          flow_sheets.map { |k, v| v.filename.gsub(/\.txt$/, '') },
            ac_specs:       ac_specset_sheets.map { |k, v| v.filename.gsub(/\.txt$/, '') },
            dc_specs:       dc_specset_sheets.map { |k, v| v.filename.gsub(/\.txt$/, '') },
            patsets:        patset_sheets.map { |k, v| v.filename.gsub(/\.txt$/, '') },
            patgroups:      patgroup_sheets.map { |k, v| v.filename.gsub(/\.txt$/, '') },
            bintables:      [],
            cz:             [],
            test_procs:     [],
            mix_sig_timing: [],
            wave_defs:      [],
            psets:          [],
            sigs_port_map:  [],
            fract_bus:      [],
            comment:        nil
          }.merge(options)

          program_jobs('Jobs').add(jname, options)
        end

        def reference(reference, options = {})
          options = {
            comment: nil
          }.merge(options)

          references('Refs').add(reference, options)
        end
      end
    end
  end
end
