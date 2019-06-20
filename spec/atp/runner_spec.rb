require 'spec_helper'

describe 'The Runner' do
  include OrigenTesters::ATP::FlowAPI

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  def run(options={})
    OrigenTesters::ATP::Formatters::Basic.run(atp.ast, options)
  end

  it "is alive" do
    test :test1, id: :t1
    if_enabled :bitmap do
      test :test2
      test :test3, if_failed: :t1
    end

    run.should == <<-END
test1
    END
  end

  it "can enable flow flags" do
    test :test1, id: :t1
    if_enabled :bitmap do
      test :test2
      test :test3, if_failed: :t1
    end

    run.should == <<-END
test1
    END

    run(enable: "bitmap").should == <<-END
test1
test2
    END
  end

  it "can assume test failures" do
    test :test1, id: :t1
    test :test1, id: :t2
    if_enabled :bitmap do
      test :test2
      test :test3, if_failed: :t1
      test :test4, if_passed: :t2
    end

    run(enable: "bitmap").should == <<-END
test1
test1
test2
test4
    END

    run(enable: "bitmap", failed_test_ids: "t1").should == <<-END
test1 F
test1
test2
test3
test4
    END

    run(enable: "bitmap", failed_test_ids: ["t1", "t2"]).should == <<-END
test1 F
test1 F
test2
test3
    END

  end

  it "can enable a job" do
    test :test1
    test :test2, if_job: :j1
    test :test3, if_job: :j2
    test :test4, unless_job: :j2
    test :test5, if_job: [:j1, :j2]
    test :test6, unless_job: [:j1, :j2]

    run(job: "j1").should == <<-END
test1
test2
test4
test5
    END

    run(job: "j2").should == <<-END
test1
test3
test5
    END

    run(job: "j3").should == <<-END
test1
test4
test6
    END
  end

  it 'can handle a speed binning flow' do

    log "Speed binning example bug from video 5"

    group "200Mhz", id: :g200 do
      test :test200_1
      test :test200_2
      test :test200_3
    end

    group "100Mhz", id: :g100, if_failed: :g200 do
      test :test100_1, bin: 5
      test :test100_2, bin: 5
      test :test100_3, bin: 5
    end

    pass 2, if_ran: :g100
    pass 1, softbin: 1
      
      
    run.should == <<-END
test200_1
test200_2
test200_3
PASS 1 1
    END

    run(failed_test_ids: ['t1']).should == <<-END
test200_1 F
test200_2
test200_3
test100_1
test100_2
test100_3
PASS 2
    END

    run(failed_test_ids: ['t1','t5']).should == <<-END
test200_1 F
test200_2
test200_3
test100_1
test100_2 F
FAIL 5
    END
  end 

  it "can handle test failures" do

    test :test1, id: :t1
    test :test1, id: :t2
    if_enabled :bitmap do
      test :test2
      test :test3, if_failed: :t1
      test :test4, if_passed: :t2
    end

    run(enable: "bitmap").should == <<-END
test1
test1
test2
test4
    END

    run(enable: "bitmap", failed_test_ids: "t1").should == <<-END
test1 F
test1
test2
test3
test4
    END

    run(enable: "bitmap", failed_test_ids: ["t1", "t2"]).should == <<-END
test1 F
test1 F
test2
test3
    END

  end
end
