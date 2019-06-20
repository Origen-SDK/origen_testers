require 'spec_helper'

describe 'The AST validators' do
  include OrigenTesters::ATP::FlowAPI

  before :each do
    OrigenTesters::ATP::Validator.testing = true
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  def name
    "Validators spec"
  end

  it "duplicate IDs are caught" do
    test :test1, id: :t1
    test :test2
    test :test3, id: :t1

    expect { atp.ast }.to raise_error(SystemExit).
      and output(/Test ID t1 is defined more than once in flow sort1/).to_stdout
  end

  it "missing IDs are caught" do
    test :test1
    test :test2
    test :test3, if_failed: :t1

    expect { atp.ast }.to raise_error(SystemExit).
      and output(/Test ID t1 is referenced in flow sort1/).to_stdout
  end

  it "positive and negative job conditions can't be mixed" do
    test :test1, if_job: "p1"
    test :test2, unless_job: "p2"

    atp.ast(add_ids: false).should ==
        s(:flow,
          s(:name, "sort1"),
          s(:if_job, "p1",
            s(:test,
              s(:object, "test1"))),
          s(:unless_job, "p2",
            s(:test,
              s(:object, "test2"))))

    if_job "p1" do
      test :test3
      test :test4, unless_job: "p2"
    end

    expect { atp.ast }.to raise_error(SystemExit).
      and output(/if_job and unless_job conditions cannot both be applied to the same tests/).to_stdout
  end

  it "if_job names can't start with a negative symbol" do
    test :test1, if_job: '!p1'

    expect { atp.ast }.to raise_error(SystemExit).
      and output(/Job names should not be negated, use unless_job/).to_stdout
  end

  it "unless_job names can't start with a negative symbol" do
    test :test1, unless_job: '!p1'

    expect { atp.ast }.to raise_error(SystemExit).
      and output(/Job names should not be negated, use unless_job/).to_stdout
  end
end
