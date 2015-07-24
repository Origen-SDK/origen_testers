module Testers
  class IGXLBasedTester
    class Parser
      autoload :Flows,   'testers/igxl_based_tester/parser/flows'
      autoload :Flow,   'testers/igxl_based_tester/parser/flow'
      autoload :FlowLine,   'testers/igxl_based_tester/parser/flow_line'
      autoload :TestInstances,   'testers/igxl_based_tester/parser/test_instances'
      autoload :TestInstance,   'testers/igxl_based_tester/parser/test_instance'
      autoload :PatternSets,   'testers/igxl_based_tester/parser/pattern_sets'
      autoload :PatternSet,   'testers/igxl_based_tester/parser/pattern_set'
      autoload :DCSpecs,   'testers/igxl_based_tester/parser/dc_specs'
      autoload :DCSpec,   'testers/igxl_based_tester/parser/dc_spec'
      autoload :ACSpecs,   'testers/igxl_based_tester/parser/ac_specs'
      autoload :ACSpec,   'testers/igxl_based_tester/parser/ac_spec'
      autoload :Descriptions,   'testers/igxl_based_tester/parser/descriptions'

      def reset
        @flows = nil
        @test_instances = nil
        @pattern_sets = nil
        @dc_specs = nil
        @ac_specs = nil
      end

      def descriptions
        @descriptions ||= Descriptions.new(parser: self)
      end

      # Returns an array of test flows
      def flows
        @flows ||= Flows.new(parser: self)
      end

      def test_instances
        @test_instances ||= TestInstances.new(parser: self)
      end
      alias_method :instances, :test_instances

      def pattern_sets
        @pattern_sets ||= PatternSets.new(parser: self)
      end
      alias_method :patsets, :pattern_sets
      alias_method :pat_sets, :pattern_sets

      def dc_specs
        @dc_specs ||= DCSpecs.new(parser: self)
      end

      def ac_specs
        @ac_specs ||= ACSpecs.new(parser: self)
      end

      def inspect
        "<Parsed Program: Flows: #{flows.size}>"
      end

      # Parse a file, array of files, or a directory.
      #
      # This can be called multiple times to add new files to the
      # program model.
      def parse(file)
        Origen.log.info ''
        Origen.log.info "Parsing J750 test program from: #{file}"
        Origen.log.info ''
        reset
        # Note use of local file handler here, this should be how it is
        # done globally, otherwise we can run into hard to debug problems
        # due to state/reference dir changes in the single Origen.file_handler
        Origen::FileHandler.new.resolve_files(file) do |f|
          parse_file(f)
        end
        Origen.log.info ''
        self
      end

      def parse_file(file)
        line = File.readlines(file).first
        begin
          if line =~ /Flow Table/
            flows.import(file)
          elsif line =~ /Instances/
            test_instances.import(file)
          elsif line =~ /Pattern Sets/
            patsets.import(file)
          elsif line =~ /DC Spec/
            dc_specs.import(file)
          else
            puts "Skipped (un-supported file type): #{file}"
          end
        rescue Exception => e
          if e.is_a?(ArgumentError) && e.message =~ /invalid byte sequence/
            puts "Skipped (not ASCII): #{file}"
          else
            puts e.message
            puts e.backtrace
            exit 1
          end
        end
      end
    end
  end
end
