module OrigenTesters
  module IGXLBasedTester
    class Base
      module Generator
        extend ActiveSupport::Concern

        autoload :Placeholder, 'origen_testers/generator/placeholder'

        included do
          include Interface  # adds the interface helpers/Origen hook-up
        end

        # This is just to give all interfaces an initialize that takes
        # one argument. The super is important for cases where this module
        # is included late via Testers::ProgramGenerators
        def initialize(options = {})
          super
        end

        def add_til(name, methods)
          custom_tils[name] = methods
        end
        alias_method :add_test_instance_library, :add_til

        # @api private
        def at_flow_start
          unless Origen.interface.resources_mode?
            flow.at_flow_start if flow
          end
          @@pinmaps_filename = nil
          @@test_instances_filename = nil
          @@patsets_filename = nil
          @@patgroups_filename = nil
          @@edgesets_filename = nil
          @@timesets_filename = nil
          @@levelsets_filename = nil
          @@ac_specsets_filename = nil
          @@dc_specsets_filename = nil
          @@global_specs_filename = nil
          @@jobs_filename = nil
          @@references_filename = nil
        end

        # @api private
        def at_run_start
          flow.at_run_start
          @@pinmap_sheets = nil
          @@test_instance_sheets = nil
          @@patset_sheets = nil
          @@flow_sheets = nil
          @@patgroup_sheets = nil
          @@edgeset_sheets = nil
          @@timeset_sheets = nil
          @@levelset_sheets = nil
          @@ac_specset_sheets = nil
          @@dc_specset_sheets = nil
          @@global_spec_sheets = nil
          @@job_sheets = nil
          @@reference_sheets = nil
        end
        alias_method :reset_globals, :at_run_start

        # Convenience method to allow the current name for the test instance,
        # patsets, patgroups and timesets sheets to be set to the same value.
        #
        #   # my j750 interface
        #
        #   resources_filename = "common"
        #
        #   # The above is equivalent to:
        #
        #   pinmaps_filename = "common"
        #   test_instances_filename = "common"
        #   patsets_filename = "common"
        #   patgroups_filename = "common"
        #   edgesets_filename = "common"
        #   timesets_filename = "common"
        #   levelsets_filename = "common"
        #   ac_specsets_filename = "common"
        #   dc_specsets_filename = "common"
        #   global_specs_filename = "common"
        #   jobs_filename = "common"
        #   references_filename = "common"
        def resources_filename=(name)
          self.pinmaps_filename = name
          self.test_instances_filename = name
          self.patsets_filename = name
          self.patgroups_filename = name
          self.edgesets_filename = name
          self.timesets_filename = name
          self.levelsets_filename = name
          self.ac_specsets_filename = name
          self.dc_specsets_filename = name
          self.global_specs_filename = name
          self.jobs_filename = name
          self.references_filename = name
          self.pattern_references_name = name
        end

        # Set the name of the current pinmap sheet. This does not change
        # the name of the current sheet, but rather sets the name of the sheet that
        # will be generated the next time you access pinmaps.
        def pinmaps_filename=(name)
          @pinmaps_filename = name
          @@pinmaps_filename = name
        end

        # Set the name of the current test instances sheet. This does not change
        # the name of the current sheet, but rather sets the name of the sheet that
        # will be generated the next time you access test_instances.
        def test_instances_filename=(name)
          @test_instances_filename = name
          @@test_instances_filename = name
        end

        # Set the name of the current pattern sets sheet. This does not change
        # the name of the current sheet, but rather sets the name of the sheet that
        # will be generated the next time you access patsets.
        def patsets_filename=(name)
          @patsets_filename = name
          @@patsets_filename = name
        end

        # Set the name of the current pattern groups sheet. This does not change
        # the name of the current sheet, but rather sets the name of the sheet that
        # will be generated the next time you access patgroups.
        def patgroups_filename=(name)
          @patgroups_filename = name
          @@patgroups_filename = name
        end

        # Set the name of the current edgesets sheet. This does not change
        # the name of the current sheet, but rather sets the name of the sheet that
        # will be generated the next time you access patgroups.
        def edgesets_filename=(name)
          @edgesets_filename = name
          @@edgesets_filename = name
        end

        # Set the name of the current timesets sheet. This does not change
        # the name of the current sheet, but rather sets the name of the sheet that
        # will be generated the next time you access patgroups.
        def timesets_filename=(name)
          @timesets_filename = name
          @@timesets_filename = name
        end

        # Set the name of the current levelsets sheet. This does not change
        # the name of the current sheet, but rather sets the name of the sheet that
        # will be generated the next time you access patgroups.
        def levelsets_filename=(name)
          @levelsets_filename = name
          @@levelsets_filename = name
        end

        # Set the name of the current AC specsets sheet. This does not change
        # the name of the current sheet, but rather sets the name of the sheet that
        # will be generated the next time you access patgroups.
        def ac_specsets_filename=(name)
          @ac_specsets_filename = name
          @@ac_specsets_filename = name
        end

        # Set the name of the current DC specsets sheet. This does not change
        # the name of the current sheet, but rather sets the name of the sheet that
        # will be generated the next time you access patgroups.
        def dc_specsets_filename=(name)
          @dc_specsets_filename = name
          @@dc_specsets_filename = name
        end

        # Set the name of the global specs sheet. This does not change
        # the name of the current sheet, but rather sets the name of the sheet that
        # will be generated the next time you access patgroups.
        def global_specs_filename=(name)
          @global_specs_filename = name
          @@global_specs_filename = name
        end

        # Set the name of the jobs sheet. This does not change
        # the name of the current sheet, but rather sets the name of the sheet that
        # will be generated the next time you access patgroups.
        def jobs_filename=(name)
          @jobs_filename = name
          @@jobs_filename = name
        end

        # Set the name of the references sheet. This does not change
        # the name of the current sheet, but rather sets the name of the sheet that
        # will be generated the next time you access patgroups.
        def references_filename=(name)
          @references_filename = name
          @@references_filename = name
        end

        # Returns the name of the current pinmaps sheet
        def pinmaps_filename
          @@pinmaps_filename ||= @pinmaps_filename || 'global'
        end

        # Returns the name of the current test instances sheet
        def test_instances_filename
          @@test_instances_filename ||= @test_instances_filename || 'global'
        end

        # Returns the name of the current pat sets sheet
        def patsets_filename
          @@patsets_filename ||= @patsets_filename || 'global'
        end

        # Returns the name of the current pat groups sheet
        def patgroups_filename
          @@patgroups_filename ||= @patgroups_filename || 'global'
        end

        # Returns the name of the current edgesets sheet
        def edgesets_filename
          @@edgesets_filename ||= @edgesets_filename || 'global'
        end

        # Returns the name of the current timesets sheet
        def timesets_filename
          @@timesets_filename ||= @timesets_filename || 'global'
        end

        # Returns the name of the current levelsets sheet
        def levelsets_filename
          @@levelsets_filename ||= @levelsets_filename || 'global'
        end

        # Returns the name of the current AC specset sheet
        def ac_specsets_filename
          @@ac_specsets_filename ||= @ac_specsets_filename || 'global'
        end

        # Returns the name of the current DC specset sheet
        def dc_specsets_filename
          @@dc_specsets_filename ||= @dc_specsets_filename || 'global'
        end

        # Returns the name of the current global spec sheet
        def global_specs_filename
          @@global_specs_filename ||= @global_specs_filename || 'global'
        end

        # Returns the name of the current job sheet
        def jobs_filename
          @@jobs_filename ||= @jobs_filename || 'global'
        end

        # Returns the name of the current references sheet
        def references_filename
          @@references_filename ||= @references_filename || 'global'
        end

        # Returns a hash containing all pinmap sheets
        def pinmap_sheets
          @@pinmap_sheets ||= {}
        end

        # Returns a hash containing all test instance sheets
        def test_instance_sheets
          @@test_instance_sheets ||= {}
        end

        # Returns a hash containing all pat set sheets
        def patset_sheets
          @@patset_sheets ||= {}
        end

        # Returns a hash containing all flow sheets
        def flow_sheets
          @@flow_sheets ||= {}
        end

        # Returns a hash containing all pat group sheets
        def patgroup_sheets
          @@patgroup_sheets ||= {}
        end

        # Returns a hash containing all edgeset sheets
        def edgeset_sheets
          @@edgeset_sheets ||= {}
        end

        # Returns a hash containing all timeset sheets
        def timeset_sheets
          @@timeset_sheets ||= {}
        end

        # Returns a hash containing all levelset sheets
        def levelset_sheets
          @@levelset_sheets ||= {}
        end

        # Returns a hash containing all AC specsets sheets
        def ac_specset_sheets
          @@ac_specset_sheets ||= {}
        end

        # Returns a hash containing all DC specsets sheets
        def dc_specset_sheets
          @@dc_specset_sheets ||= {}
        end

        # Returns a hash containing all global spec sheets
        def global_spec_sheets
          @@global_spec_sheets ||= {}
        end

        # Returns a hash containing all job sheets
        def job_sheets
          @@job_sheets ||= {}
        end

        # Returns a hash containing all reference sheets
        def reference_sheets
          @@reference_sheets ||= {}
        end

        # Returns an array containing all sheet generators where a sheet generator is a flow,
        # test instance, patset, pat group, edgeset, timeset, AC/DC/Global spec, job,
        # or reference sheet.
        # All Origen program generators must implement this method
        def sheet_generators # :nodoc:
          g = []
          # Generate all of these sheets verbatim
          [pinmap_sheets, flow_sheets, test_instance_sheets, patset_sheets,
           patgroup_sheets, levelset_sheets, ac_specset_sheets, dc_specset_sheets,
           global_spec_sheets, job_sheets, reference_sheets].each do |sheets|
            sheets.each do |name, sheet|
              g << sheet
            end
          end
          # Choose whether to generate edgeset/timset or timeset_basic sheets
          #  * Skip edgeset sheet generation when timeset_basic is selected
          [edgeset_sheets, timeset_sheets].each do |sheets|
            sheets.each do |name, sheet|
              next if sheet.class.name =~ /Edgesets$/ && sheet.ts_basic

              g << sheet
            end
          end
          g
        end

        # Returns an array containing all flow sheet generators.
        # All Origen program generators must implement this method
        def flow_generators
          g = []
          flow_sheets.each do |name, sheet|
            g << sheet
          end
          g
        end

        # Returns the current pinmaps sheet (as defined by the current value of
        # pinmaps_filename).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def pinmaps(filename = pinmaps_filename)
          f = filename.to_sym
          return pinmap_sheets[f] if pinmap_sheets[f]

          p = platform::Pinmap.new
          p.filename = f
          pinmap_sheets[f] = p
        end
        alias_method :pin_maps, :pinmaps

        # Returns the current test instances sheet (as defined by the current value of
        # test_instances_filename).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def test_instances(filename = test_instances_filename)
          f = filename.to_sym
          return test_instance_sheets[f] if test_instance_sheets[f]

          t = platform::TestInstances.new
          t.filename = f
          test_instance_sheets[f] = t
        end

        # Returns the current pattern sets sheet (as defined by the current value of
        # patsets_filename).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def patsets(filename = patsets_filename)
          f = filename.to_sym
          return patset_sheets[f] if patset_sheets[f]

          p = platform::Patsets.new
          p.filename = f
          patset_sheets[f] = p
        end
        alias_method :pat_sets, :patsets
        alias_method :pattern_sets, :patsets

        # Returns the current pattern subroutine sheet (as defined by the current value of
        # patsubrs_filename).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def patsubrs(filename = patsubrs_filename)
          f = filename.to_sym
          return patsubr_sheets[f] if patsubr_sheets[f]

          p = platform::Patsubrs.new
          p.filename = f
          patsubr_sheets[f] = p
        end
        alias_method :pat_subrs, :patsubrs
        alias_method :pattern_subrs, :patsubrs

        # Returns the current flow sheet (as defined by the name of the current top
        # level flow source file).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def flow(filename = nil)
          if filename || Origen.file_handler.current_file
            filename ||= Origen.file_handler.current_file.basename('.rb').to_s
            # DH here need to reset the flow!!
            f = filename.to_sym
            return flow_sheets[f] if flow_sheets[f] # will return flow if already existing

            p = platform::Flow.new
            p.inhibit_output if Origen.interface.resources_mode?
            p.filename = f
            flow_sheets[f] = p
          end
        end

        # Returns the current pattern groups sheet (as defined by the current value of
        # patgroups_filename).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def patgroups(filename = patgroups_filename)
          f = filename.to_sym
          return patgroup_sheets[f] if patgroup_sheets[f]

          p = platform::Patgroups.new
          p.filename = f
          patgroup_sheets[f] = p
        end
        alias_method :pat_groups, :patgroups
        alias_method :pattern_groups, :patgroups

        # Returns the current collection of edges that are defined.  These are
        # used in support of creating edgeset/timeset sheets.  They do not have
        # an associated sheet of their own.
        def edges
          @@edges ||= platform::Edges.new
        end
        alias_method :edge_collection, :edges

        # Returns the current edgesets sheet (as defined by the current value of
        # edgesets_filename).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def edgesets(filename = edgesets_filename, options = {})
          options = {
            timeset_basic: false
          }.merge(options)

          f = filename.to_sym
          return edgeset_sheets[f] if edgeset_sheets[f]

          e = platform::Edgesets.new(options)
          e.filename = f
          edgeset_sheets[f] = e
        end
        alias_method :edge_sets, :edgesets

        # Returns the current timesets or timesets_basic sheet (as defined by the current value of
        # timesets_filename).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def timesets(filename = timesets_filename, options = {})
          options = {
            timeset_basic: false
          }.merge(options)

          f = filename.to_sym
          return timeset_sheets[f] if timeset_sheets[f]

          case options[:timeset_basic]
          when true
            t = platform::TimesetsBasic.new(options)
          when false
            t = platform::Timesets.new(options)
          end
          t.filename = f
          timeset_sheets[f] = t
        end
        alias_method :time_sets, :timesets
        alias_method :timing_sets, :timesets

        # Returns the current collection of levels that are defined.  These are
        # used in support of creating levelset sheets.  They do not have
        # an associated sheet of their own.
        def levels
          @@levels ||= platform::Levels.new
        end
        alias_method :level_collection, :levels

        # Returns the current levelsets sheet (as defined by the current value of
        # levelsets_filename).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def levelsets(filename = levelsets_filename)
          f = filename.to_sym
          return levelset_sheets[f] if levelset_sheets[f]

          t = platform::Levelset.new
          t.filename = f
          levelset_sheets[f] = t
        end

        # Returns the current AC specset sheet (as defined by the current value of
        # ac_specsets_filename).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def ac_specsets(filename = ac_specsets_filename)
          f = filename.to_sym
          return ac_specset_sheets[f] if ac_specset_sheets[f]

          s = platform::ACSpecsets.new
          s.filename = f
          ac_specset_sheets[f] = s
        end

        # Returns the current DC specset sheet (as defined by the current value of
        # dc_specsets_filename).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def dc_specsets(filename = dc_specsets_filename)
          f = filename.to_sym
          return dc_specset_sheets[f] if dc_specset_sheets[f]

          s = platform::DCSpecsets.new
          s.filename = f
          dc_specset_sheets[f] = s
        end

        # Returns the current global spec sheet (as defined by the current value of
        # global_specs_filename).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def global_specs(filename = global_specs_filename)
          f = filename.to_sym
          return global_spec_sheets[f] if global_spec_sheets[f]

          s = platform::GlobalSpecs.new
          s.filename = f
          global_spec_sheets[f] = s
        end

        # Returns the current job sheet (as defined by the current value of
        # jobs_filename).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def program_jobs(filename = jobs_filename)
          f = filename.to_sym
          return job_sheets[f] if job_sheets[f]

          j = platform::Jobs.new
          j.filename = f
          job_sheets[f] = j
        end

        # Returns the current reference sheet (as defined by the current value of
        # references_filename).
        #
        # Pass in a filename argument to have a specific sheet returned instead.
        #
        # If the sheet does not exist yet it will be created.
        def references(filename = references_filename)
          f = filename.to_sym
          return reference_sheets[f] if reference_sheets[f]

          r = platform::References.new
          r.filename = f
          reference_sheets[f] = r
        end

        private

        # Custom test instance libraries
        def custom_tils
          @custom_tils ||= {}
        end
      end
    end
  end
end
