require_relative './matchers'
require_relative './validators'

RSpec.shared_examples(:platform_interface) do |platform|
  context "with platform #{platform.decompiler.name}" do
    before :context do
      Origen.app.target.temporary = 'empty.rb'
      Origen.app.environment.temporary = platform.env
      Origen.target.load!
    end

    # Each platform will have a standard block tests associated with it.
    # The purpose here being to verify that the platform in question is
    #   1. Providing the standard decompiler interface
    #   2. Still able to supply platform-specific options.
    #
    # This is achieved by running some 'known patterns', namely the
    # 'workout' and 'delay' patterns and comparing against known results.
    #
    # The driver also supports some platform specific options, meaning
    # that this driver can double as a general test interface as well.
      
    # The patterns below are required by the interface driver.
    describe 'Interface-required patterns' do
      # These patterns should decompile and pass the pattern validator
      describe 'working patterns' do
        describe 'decompiling and validating the \'simple\' pattern... (single vector)' do
          include_examples(:pattern_validator, :simple, platform)
        end

        describe 'decompiling and validating the \'delay\' pattern...' do
          include_examples(:pattern_validator, :delay, platform)
        end

        describe 'decompiling and validating the \'workout\' pattern...' do
          include_examples(:pattern_validator, :workout, platform)
        end
        
        (platform.patterns.keys - [:workout]).each do |name|
          describe "decompiling and validating platform-specific pattern #{name}" do
            include_examples(:pattern_validator, name, platform)
          end
        end
      end
      
      # These are some corner cases that should decompile and pass the
      # pattern validator, but don't necessarily reflect the usual pattern.
      # That is, technically correct patterns.
      describe 'corner-case patterns' do
        it 'can decomple a pattern that does not contain a pattern header' do
          model = platform.decompile(platform.corner_case('no_pattern_header'))
          
          # Expecting:
          #   1. The pattern to parse.
          #   2. The frontmatter to not be nil. Should at least give us a frontmatter class.
          #   3. The pattern header method should still be valid, but should be empty.
          expect(model).to be_a(platform.decompiler)
          expect(model.frontmatter).to be_a(OrigenTesters::Decompiler::Pattern::Frontmatter)
          expect(model.frontmatter.pattern_header).to be_a(Array)
          expect(model.frontmatter.pattern_header).to be_empty
          expect(model.pinlist.pins).to match_pin_names(rspec.dut.pins.keys)
        end

        it 'can decompile a pattern that does not contain any frontmatter' do
          model = platform.decompile(platform.corner_case('no_frontmatter'))

          # Expecting:
          #   1. The pattern to parse.
          #   2. The frontmatter to not be nil. Should at least give us a frontmatter class.
          #   3. The pattern header method should still be valid, but should be empty.
          expect(model).to be_a(platform.decompiler)
          expect(model.frontmatter).to be_a(OrigenTesters::Decompiler::Pattern::Frontmatter)
          expect(model.frontmatter.pattern_header).to be_a(Array)
          expect(model.frontmatter.pattern_header).to be_empty
          expect(model.pinlist.pins).to match_pin_names(rspec.dut.pins.keys)
        end

        if platform.respond_to?(:corner_cases)
          describe "corner cases specific to #{platform.name}" do
            platform.corner_cases(self)
          end
        end

      end

      # Error conditions. These patterns are expected to fail decompilation,
      # but should do so with some caught, helpful error, rather than just blowing up
      # with a stack trace.
      # These are just general cases though.
      
      describe 'error condition patterns' do
        it 'complains if no pinlist is found in the pattern source' do
          expect {
            platform.decompile(platform.error_condition('no_pinlist'))
          }.to raise_error(OrigenTesters::Decompiler::ParseError, /Could not locate the pinlist start in pattern/)
        end

        it 'complains if the pattern frontmatter cannot be parsed' do
          expect {
            platform.decompile(platform.error_condition('parse_failure_frontmatter'))
          }.to raise_error(OrigenTesters::Decompiler::ParseError, /Could not parse the frontmatter of pattern/)
        end

        it 'complains if the pinlist cannot be parsed' do
          expect {
            platform.decompile(platform.error_condition('parse_failure_pinlist'))
          }.to raise_error(OrigenTesters::Decompiler::ParseError, /Could not parse the pinlist of pattern/)
        end

        it 'complains if the vector body cannot be found' do
          expect {
            platform.decompile(platform.error_condition('no_vector_body'))
          }.to raise_error(OrigenTesters::Decompiler::ParseError, /Could not locate the vector body in pattern/)
        end

        it 'complains if the vector elements cannot be parsed' do
          expect {
            model = platform.decompile(platform.error_condition('parse_failure_vector'))
            
            # The entire vector body won't actually be parsed at decompiled pattern's initialization,
            # so kick off the vectors here to trigger the error.
            model.collect_vectors
          }.to raise_error(OrigenTesters::Decompiler::ParseError, /Could not parse the vector body of pattern/)
        end

        it 'complains if no first vector can be found' do
          expect {
            model = platform.decompile(platform.error_condition('no_first_vector'))
            model.first_vector
          }.to raise_error(OrigenTesters::Decompiler::ParseError, /Could not locate the first vector in pattern/)
        end

        it 'complains if the pattern source is empty' do
          expect {
            platform.decompile(platform.error_condition('empty_file'))
          }.to raise_error(OrigenTesters::Decompiler::ParseError, /Empty or non-readable pattern file/)
        end
        
        if platform.respond_to?(:error_conditions)
          describe "error conditions specific to #{platform.name}" do
            platform.error_conditions(self)
          end
        end

      end
    end
    
    # Clean up after this context has run.
    after :context do
      Origen.app.target.temporary = nil
      Origen.app.environment.temporary = nil
      Origen.target.load!
    end
  end
end
