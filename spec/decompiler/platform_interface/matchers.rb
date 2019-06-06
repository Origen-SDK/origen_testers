# Custom matchers for platform nodes

RSpec::Matchers.define :match_vector do |expected, index|
  
  match do |actual|
    @failures = []
    unless actual.class == OrigenTesters::Decompiler::Pattern::Vector
      @failures << "expected class OrigenTesters::Decompiler::Pattern::Vector -> received #{actual.class}"
    end
    
    # This will come in from JSON as a string. Need to cast it to an integer for
    # the comparison to work.
    unless actual.repeat == expected[:repeat].to_i
      @failures << "expected repeat count #{expected[:repeat]} -> received #{actual.repeat}"
    end
    
    unless actual.timeset == expected[:timeset]
      @failures << "expected timeset '#{expected[:timeset]}' -> received '#{actual.timeset}'"
    end
        
    unless actual.pin_states == expected[:pin_states]
      @failures << "expected pin states #{expected[:pin_states]} -> received #{actual.pin_states}"
    end
    
    unless actual.comment == expected[:comment]
      @failures << "expected comment '#{expected[:comment]}' -> received '#{actual.comment}'"
    end
    
    expected[:platform_nodes].each do |n, v|
      if !actual.processor.respond_to?(n.to_sym)
        @failures << "expected platform node '#{n}' with value '#{v}', but actual vector's processor does not contain a #{n} platform node"
      elsif actual.send(n) != v
        @failures << "expected platform node '#{n}' with value '#{v}' -> received '#{v}'"
      end
    end
        
    @failures.empty?
  end

  failure_message do |actual|
    message = ["vector at index #{index} failed:"]
    message += @failures.collect { |f| " #{f}" }
    message.join("\n")
  end
end

