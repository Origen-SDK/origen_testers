# This validates a pattern against its previously genetrated, previously approved,
# pattern model. The tests are generated in the compilation stage (not during 
# the tests runtime) and are based on the pattern's model, NOT on the the
# resulting decompiled pattern. Thus, these tests will be constant given that
# the approved pattern model is constant.
# This is general purpose validator that should be applicable to all supported
# platforms. This will validate that the platform correctly decompiles a pattern
# and implements the OrigenTesters::Decompiler::Pattern interface.
RSpec.shared_examples(:pattern_validator) do |target_pattern, platform|
  model = platform.pattern_model(target_pattern)
  unless File.exist?(model)
    fail "Pattern validator could not find pattern model for target pattern :#{target_pattern} (#{model})"
  end

  expected_model = YAML.load_file(model).with_indifferent_access
  expected_model[:pinlist]['pinlist'].map! { |p| p.to_sym }
  
  context "with pattern #{platform.patterns[target_pattern]}" do

    it "can decompile the pattern" do
      expect(platform.decompiler.instance_methods).to include(:decompile)

      platform.current = platform.decompile(platform.approved_pat(target_pattern))
      expect(platform.current).to be_a(platform.decompiler)
    end
    
    it 'can access the pattern\'s frontmatter API' do
      expect(platform.current).to respond_to(:frontmatter)
      expect(platform.current.frontmatter).to be_a(OrigenTesters::Decompiler::Pattern::Frontmatter)
    end

    it 'can query the pattern frontmatter\'s comments' do
      expect(platform.current.frontmatter.comments).to eql(expected_model[:frontmatter][:comments])
    end
    
    it 'can query the pattern\'s pattern header' do
      expect(platform.current.frontmatter.pattern_header).to eql(expected_model[:frontmatter][:pattern_header])
    end
    
    it 'can access the pattern\'s pin list API' do
      expect(platform.current).to respond_to(:pinlist)
      expect(platform.current.pinlist).to be_a(OrigenTesters::Decompiler::Pattern::Pinlist)
    end

    it 'can query the pattern\'s pin list' do
      expect(platform.current.pinlist.pins).to eql(expected_model[:pinlist][:pinlist])
    end
    
    # The first vector is particularly important, since it sets the initial stage
    # during execution or conversion, so single this out to confirm that the
    # 'first vector element' does, in fact, match the expected first vector.
    #
    # That said, not all testers require a 'first vector', so if its missing from
    # the pattern model, assume the platform doesn't require it.
    # Whether or not such a pattern can execute or convert is a matter for the
    # platform itself to handle. Here, we're just looking for generic
    # conformation to the Decompiler::Pattern API.
    # example: the v93k allows a pattern that is just sequencer instructions,
    #          no actual vectors.
    #          This pattern has no applicable execution/conversion result,
    #          which is an implementation decision by the platform, at this time.
    expected_first_vector = expected_model[:vectors].find { |v| v[:type] == :vector }
    expected_first_vector_index = expected_model[:vectors].index { |v| v[:type] == :vector }
    unless expected_first_vector.nil?
      include_examples(:validate_vector_element, 
        expected: expected_first_vector, 
        index: expected_first_vector_index,
        index_key: :first_vector,
        platform: platform
      )
      
      it 'can query the initial pin states (pin states from the first vector)' do
        expect(platform.current).to respond_to(:first_pin_states)
        expect(platform.current.method(:initial_pin_states)).to eql(platform.current.method(:first_pin_states))

        expect(platform.current.first_pin_states).to eql(expected_first_vector[:pin_states])
      end
      
      it 'can query the initial timeset (timeset on the first vector)' do
        expect(platform.current).to respond_to(:first_timeset)
        expect(platform.current.method(:initial_timeset)).to eql(platform.current.method(:first_timeset))

        expect(platform.current.first_timeset).to eql(expected_first_vector[:timeset])
      end
    end
    
    # RSepc unrolls all the tests before it actually starts running anything.
    # The plan then is to iterate through the known vectors from 'approved' and
    # generate a vector validator for each one.
    # NOTE: As of now, this is extreme slow as the vectors will start over
    # every time. Plans in place to add a test hook for this that won't
    # start over each time if this becomes an issue.
    expected_model[:vectors].each_with_index do |v, i|
      include_examples(:validate_vector_element,
        expected: v,
        index: i,
        platform: platform
      )
    end
    
    # The previous tests will yield a true-negative if there are extra vector elements appended to the decompiled result.
    # Add a case here just to check that the total number of vectors matches.
    it 'contains the expected number of vectors' do
      expect(expected_model[:vectors].size).to eql(platform.current.count)
    end
  end
end

# Validates a single vector element.
# The work isn't actually done here, rather this routes the vector type to various
# other validators.
RSpec.shared_examples(:validate_vector_element) do |expected:, index: nil, index_key: nil, platform:|
  case expected[:type]
    when :vector
      include_examples(:validate_vector,
        expected: expected,
        index: index,
        index_key: index_key,
        platform: platform
      )
    when :comment_block
      include_examples(:validate_comment_block,
        expected: expected,
        index: index,
        index_key: index_key,
        platform: platform,
      )
    else
      # See if this is a platform specific vector type and call the handler for it.
      # Note: the handler can do whatever here, including just 'auto-passing' the value. 
      # That's for the platform owner to decided. However, if the type can end up here, it needs a case. 
      # Otherwise, the specs will fail to build.
      platform.handle_platform_specific_vector_body_element(
        self, 
        expected[:type], 
        {
          expected: expected,
          index: index,
          index_key: index_key,
          platform: platform,
        },
      )
  end
end

# Validates a single vector given an OrigenTesters::Decompiler::Pattern::Vector object
# (decompiled from the pattern-under-test) and its expected state, given from
# the previously-approved pattern's model.
# To provide decent feedback whilst not blowing up the test count, a custom
# matcher is used to verify the vector's state.
RSpec.shared_examples(:validate_vector) do |expected:, index: nil, index_key: nil, platform: |
  context "validating vector at index #{index_key || index || 'no index provided!'}" do
    let(:vut) do
      platform.current.vector_at(index).element
    end

    it 'matches the expected vector' do
      expect(platform.current.vector_at(index).element).to match_vector(expected, index)
    end
  end
end

# Validates a comment block vector element type.
RSpec.shared_examples(:validate_comment_block) do |expected:, index:, index_key: nil, platform:|
  context platform.context_str(vector_type: :comment_block, index: index, index_key: index_key) do
    let(:cut) { platform.current.vector_at(index).element }
  
    it 'matches the comments' do
      expect(cut.comments).to eql(expected[:comments])
    end
  end
end

