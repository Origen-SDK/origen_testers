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

        def add_tml(name, methods)
          methods[:class_name] ||= name.to_s.camelize
          custom_tmls[name] = methods
        end
        alias_method :add_test_method_library, :add_tml

        # @api private
        def at_flow_start
          flow.at_flow_start
        end

        # @api private
        def at_run_start
          flow.at_run_start
          @@flow_sheets = nil
        end
        alias_method :reset_globals, :at_run_start

        def resources_filename=(name)
        end

        def flow(filename = Origen.file_handler.current_file.basename('.rb').to_s)
          f = filename.to_sym
          f = f.to_s.sub(/_resources?/, '').to_sym
          return flow_sheets[f] if flow_sheets[f] # will return flow if already existing
          p = platform::Flow.new
          p.inhibit_output if Origen.interface.resources_mode?
          p.filename = f
          p.test_suites ||= platform::TestSuites.new(p)
          p.test_methods ||= platform::TestMethods.new(p)
          p.pattern_master ||= platform::PatternMaster.new(p)
          flow_sheets[f] = p
        end

        # Returns a top-level pattern master file which will contain all patterns from
        # all flows. Additionally each flow has its own pattern master file containing
        # only the patterns for the specific flow.
        def pattern_master
          @pattern_master ||= begin
            m = platform::PatternMaster.new(manually_register: true)
            name = 'complete.pmfl'
            name = "#{Origen.config.program_prefix}_#{name}" if Origen.config.program_prefix
            m.filename = name
            m
          end
        end

        # Generates a pattern compiler configuration file (.aiv) to compile all
        # patterns referenced in all flows.
        def pattern_compiler
          @pattern_compiler ||= begin
            m = platform::PatternCompiler.new(manually_register: true)
            name = 'complete.aiv'
            name = "#{Origen.config.program_prefix}_#{name}" if Origen.config.program_prefix
            m.filename = name
            m
          end
        end

        def test_suites
          flow.test_suites
        end

        def test_methods
          flow.test_methods
        end

        def flow_sheets
          @@flow_sheets ||= {}
        end

        # Returns an array containing all sheet generators.
        # All Origen program generators must implement this method
        def sheet_generators # :nodoc:
          g = []
          flow_sheets.each do |_name, sheet|
            g << sheet
            g << sheet.pattern_master
          end
          g << pattern_master if pattern_master
          g << pattern_compiler unless referenced_subroutine_patterns.empty? && referenced_patterns.empty?
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
