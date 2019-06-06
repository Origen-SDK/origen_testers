# Custom matchers for the non-pattern validators
# (they have their own matchers file in ./platform_interface

# Matches the pin names and sizes. Pin names are compared without respect to case.
RSpec::Matchers.define :match_pins do |expected|
  
  match do |actual|
    expected.each_with_index do |(name, size), i|
      if size > 1
        # Break the pins out into individual pin names
        size.times do |i|
          return false unless actual.key?("#{name}#{i}".to_sym)
        end
      else
        return false unless (actual.key?(name) || actual.key?(name.to_s.upcase.to_sym))
      end
    end
    true
  end

  failure_message do |actual|
    "expected pins #{actual.collect { |name, pin| name.to_s + ':' + pin.size.to_s }.join(',') } to match pins #{expected.collect { |name, size| name.to_s + ':' + size.to_s }.join(',') }"
  end
end

# Matches two pin name arrays, ignoring the case and ordering of pin names.
RSpec::Matchers.define :match_pin_names do |expected|
  match do |actual|
    (expected.map { |p| p.to_s.downcase } - actual.map { |p| p.to_s.downcase }).empty?
  end
  
  failure_message do |actual|
    "expected pins #{actual.map { |pin| pin.to_s }.join(',') } to match #{expected.collect { |pin| pin.to_s }.join(',') }"
  end
end

RSpec::Matchers.define :match_approved_pattern do |expected|
  match do |actual|
    # Everything is going to be converted to J750, just for simplicity. As the decompiler grows and as new features
    # are added, may need to have per-platform reference patterns.
    return false unless File.exist?(expected)
    return false unless File.exist?(actual)
    
    # check for changes will return true if there's changes, and if there's changes we want to fail the matcher.
    !Origen.generator.check_for_changes(actual, expected)
  end
  
  failure_message do |actual|
    return "Could not find pattern output #{actual}" unless File.exist?(actual)
    return "Could not find pattern reference #{expected}" unless File.exist?(expected)
    
    "Changes occurred when comparing #{expected} to #{actual}"
  end
end

