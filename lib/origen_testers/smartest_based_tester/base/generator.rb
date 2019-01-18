module OrigenTesters
  module SmartestBasedTester
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
          @initialized = true
        end

        # @api private
        # This will be called at the start of every Flow.create block, :top_level will be
        # true when it is a top-level Flow.create block
        def _internal_startup(options)
          if options[:top_level]
            if options.key?(:unique_test_names)
              self.unique_test_names = options[:unique_test_names]
            end
            flow.flow_name = options[:flow_name]
          end
        end

        def add_tml(name, methods)
          methods[:class_name] ||= name.to_s.camelize
          custom_tmls[name] = methods
        end
        alias_method :add_test_method_library, :add_tml

        # @api private
        def at_flow_start
          f = flow
          f.at_flow_start
          # Initialize this to the value currently set on the tester, any further setting of
          # this by the interface will override
          flow.add_flow_enable = tester.add_flow_enable
          self.unique_test_names = tester.unique_test_names
          @pattern_master_filename = nil
        end

        # @api private
        def at_flow_end
          flow.at_flow_end
        end

        # @api private
        def at_run_start
          flow.at_run_start
          @@flow_sheets = nil
          @@pattern_masters = nil
          @@pattern_compilers = nil
          @@variables_files = nil
          @@limits_workbook = nil
          limits_workbook if tester.smt8? && !generating_sub_program?
        end
        alias_method :reset_globals, :at_run_start

        def resources_filename=(name)
          self.pattern_master_filename = name
          self.pattern_references_name = name
          flow.var_filename = name
        end

        def pattern_master_filename=(name)
          @pattern_master_filename = name
        end

        def pattern_master_filename
          @pattern_master_filename || 'global'
        end

        # Returns the current flow object (Origen.interface.flow)
        def flow(id = Origen.file_handler.current_file.basename('.rb').to_s)
          return @current_flow if @current_flow
          id = id.to_s.sub(/_resources?/, '')
          filename = id.split('.').last
          return flow_sheets[id] if flow_sheets[id] # will return flow if already existing
          p = platform::Flow.new
          p.inhibit_output if Origen.interface.resources_mode?
          p.filename = filename
          p.test_suites ||= platform::TestSuites.new(p)
          p.test_methods ||= platform::TestMethods.new(p)
          flow_sheets[id] = p
        end

        # @api private
        def with_flow(name)
          @flow_stack ||= []
          @current_flow = nil
          f = flow(name)
          @flow_stack << f
          @current_flow = @flow_stack.last
          yield
          @flow_stack.pop
          @current_flow = @flow_stack.last
          f
        end

        # Returns the pattern master file (.pmfl) for the current flow, by default a common pattern
        # master file called 'global' will be used for all flows.
        # To use a different one set the resources_filename at the start of the flow.
        def pattern_master
          pattern_masters[pattern_master_filename] ||= begin
            m = platform::PatternMaster.new(manually_register: true)
            name = "#{pattern_master_filename}.pmfl"
            name = "#{Origen.config.program_prefix}_#{name}" if Origen.config.program_prefix
            m.filename = name
            m.id = pattern_master_filename
            m
          end
        end

        # Returns a hash containing all pattern master generators
        def pattern_masters
          @@pattern_masters ||= {}
        end

        # Returns the pattern compiler file (.aiv) for the current flow, by default a common pattern
        # compiler file called 'global' will be used for all flows.
        # To use a different one set the resources_filename at the start of the flow.
        def pattern_compiler
          pattern_compilers[pattern_master_filename] ||= begin
            m = platform::PatternCompiler.new(manually_register: true)
            name = "#{pattern_master_filename}.aiv"
            name = "#{Origen.config.program_prefix}_#{name}" if Origen.config.program_prefix
            m.filename = name
            m.id = pattern_master_filename
            m
          end
        end

        # Returns a hash containing all pattern compiler generators
        def pattern_compilers
          @@pattern_compilers ||= {}
        end

        # Returns the variables file for the current or given flow, by default a common variable
        # file called 'global' will be used for all flows.
        # To use a different one set the resources_filename at the start of the flow.
        def variables_file(flw = nil)
          name = (flw || flow).var_filename
          variables_files[name] ||= begin
            m = platform::VariablesFile.new(manually_register: true)
            filename = "#{name}_vars.tf"
            filename = "#{Origen.config.program_prefix}_#{filename}" if Origen.config.program_prefix
            m.filename = filename
            m.id = name
            m
          end
        end

        # Returns a hash containing all variables file generators
        def variables_files
          @@variables_files ||= {}
        end

        # @api private
        def pattern_reference_recorded(name, options = {})
          # Will be called everytime a pattern reference is made that the ATE should be aware of,
          # don't need to remember it as it can be fetched from all_pattern_references later, but
          # need to instantiate a pattern master and compiler to handle it later
          pattern_master
          pattern_compiler
        end

        def test_suites
          flow.test_suites
        end

        def test_methods
          flow.test_methods
        end

        def flow_sheets
          @@flow_sheets ||= {}.with_indifferent_access
        end

        # Returns an array containing all sheet generators.
        # All Origen program generators must implement this method
        def sheet_generators # :nodoc:
          g = []
          flow_sheets.each do |_name, sheet|
            g << sheet
          end
          pattern_masters.each do |name, sheet|
            g << sheet
          end
          pattern_compilers.each do |name, sheet|
            g << sheet
          end
          variables_files.each do |name, sheet|
            g << sheet
          end
          g << limits_workbook if tester.smt8? && !generating_sub_program?
          g
        end

        # Returns an array containing all flow sheet generators.
        # All Origen program generators must implement this method
        def flow_generators
          g = []
          flow_sheets.each do |_name, sheet|
            g << sheet
          end
          g
        end

        private

        def custom_tmls
          @custom_tmls ||= {}
        end
      end
    end
  end
end
