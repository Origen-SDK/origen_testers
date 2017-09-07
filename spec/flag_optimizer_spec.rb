require 'spec_helper'
require 'origen_testers/smartest_based_tester/base/processors'

describe 'The V93K flah optimizer' do

  Processors = OrigenTesters::SmartestBasedTester::Base::Processors

  it "works at the top-level" do
    ast1 = to_ast <<-END
      (flow
        (test
          (name "test1")
          (id "test1"))
        (test-result "test1" false
          (test
            (name "test2"))))
      END

    ast2 = to_ast <<-END      
      (flow
        (test
          (name "test1")
          (id "test1"))
        (test-result "test1" false
          (test
            (name "test2"))))
      END

    Processors::FlagOptimizer.new.process(ast1).should == ast2
  end


end
