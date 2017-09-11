require 'spec_helper'
require 'origen_testers/smartest_based_tester/base/processors'

describe 'The V93K adjacent if combiner' do

  Processors = OrigenTesters::SmartestBasedTester::Base::Processors

  def process(ast)
    Processors::AdjacentIfCombiner.new.process(ast)
  end

  it "works" do
    ast1 = 
      s(:flow,
        s(:name, "prb1"),
        s(:run_flag, "SOME_FLAG", true,
          s(:test,
            s(:name, "test1"))),
        s(:run_flag, "SOME_FLAG", false,
          s(:test,
            s(:name, "test2"))))

    ast2 = 
      s(:flow,
        s(:name, "prb1"),
        s(:run_flag, "SOME_FLAG",
          s(:flag_true,
            s(:test,
              s(:name, "test1"))),
          s(:flag_false,
            s(:test,
              s(:name, "test2")))))

    process(ast1).should == ast2
  end

  it "should not combine if there is potential modification of the flag in either branch" do
    ast1 = 
      s(:flow,
        s(:name, "prb1"),
        s(:run_flag, "SOME_FLAG", true,
          s(:test,
            s(:name, "test1")),
          s(:set_run_flag, "SOME_FLAG")),
        s(:run_flag, "SOME_FLAG", false,
          s(:test,
            s(:name, "test2"))))

    ast2 = 
      s(:flow,
        s(:name, "prb1"),
        s(:run_flag, "SOME_FLAG", true,
          s(:test,
            s(:name, "test1")),
          s(:set_run_flag, "SOME_FLAG")),
        s(:run_flag, "SOME_FLAG", false,
          s(:test,
            s(:name, "test2"))))

    process(ast1).should == ast2
  end
end
