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
          flow.at_flow_start unless Origen.interface.resources_mode?
          @@test_instances_filename = nil
          @@patsets_filename = nil
          @@patgroups_filename = nil
        end

        # @api private
        def at_run_start
          flow.at_run_start
          @@test_instance_sheets = nil
          @@patset_sheets = nil
          @@flow_sheets = nil
          @@patgroup_sheets = nil
        end
        alias_method :reset_globals, :at_run_start

        # Convenience method to allow the current name for the test instance,
        # patsets and patgroups sheets to be set to the same value.
        #
        #   # my j750 interface
        #
        #   resources_filename = "common"
        #
        #   # The above is equivalent to:
        #
        #   test_instances_filename = "common"
        #   patsets_filename = "common"
        #   patgroups_filename = "common"
        def resources_filename=(name)
          self.test_instances_filename = name
          self.patsets_filename = name
          self.patgroups_filename = name
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

        # Returns an array containing all sheet generators where a sheet generator is a flow,
        # test instance, patset or pat group sheet.
        # All Origen program generators must implement this method
        def sheet_generators # :nodoc:
          g = []
          [flow_sheets, test_instance_sheets, patset_sheets, patgroup_sheets].each do |sheets|
            sheets.each do |name, sheet|
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
        def flow(filename = Origen.file_handler.current_file.basename('.rb').to_s)
          # DH here need to reset the flow!!
          f = filename.to_sym
          return flow_sheets[f] if flow_sheets[f] # will return flow if already existing
          p = platform::Flow.new
          p.inhibit_output if Origen.interface.resources_mode?
          p.filename = f
          flow_sheets[f] = p
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

        private

        # Custom test instance libraries
        def custom_tils
          @custom_tils ||= {}
        end
      end
    end
  end
end
