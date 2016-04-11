module OrigenTesters
  module Test
    class UltraFLEXInterface
      include OrigenTesters::UltraFLEX::Generator

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
        ins.lo_limit = options[:lo_limit]
        ins.hi_limit = options[:hi_limit]
        ins.scale = options[:scale]
        ins.units = options[:units]
        ins.defer_limits = options[:defer_limits]

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
          nom:     { typ:  nil }
        }.merge(options)

        ss = ac_specsets(sheet_name)
        add_ac_specs(ss, expression, options)
      end

      # Collects AC Spec object(s) from the given expression and adds them to the given Specset
      def collect_ac_specs(ssname, edge, options = {})
        options = {
          nom: { typ:  nil }
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
        vars = expression.scan(/[a-zA-Z][\w]+/).map(&:to_sym)
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
        vars = expression.scan(/[a-zA-Z][\w]+/).map(&:to_sym)
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

        global_specs('Global').add(var, job: options[:job], value: options[:value], comment: options[:comment])
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
          comment:        nil
        }.merge(options)

        references('Refs').add(reference, options)
      end
    end
  end
end
