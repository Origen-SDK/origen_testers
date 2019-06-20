require 'spec_helper'

describe 'The adjacent if combiner' do

  include OrigenTesters::ATP::FlowAPI

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  def ast(options = {})
    options = {
      optimization: :smt,
      add_ids: false
    }.merge(options)
    atp.ast(options)
  end

  it "works" do
    test :test1, if_flag: "SOME_FLAG"
    test :test2, unless_flag: "SOME_FLAG"

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_flag, "SOME_FLAG",
          s(:test,
            s(:object, "test1")),
          s(:else,
              s(:test,
                s(:object, "test2")))))
  end

  it "should not combine if there is potential modification of the flag in either branch" do
    if_flag "SOME_FLAG" do
      test :test1
      set_flag "SOME_FLAG"
    end
    test :test2, unless_flag: "SOME_FLAG"

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_flag, "SOME_FLAG",
          s(:test,
            s(:object, "test1")),
          s(:set_flag, "SOME_FLAG")),
        s(:unless_flag, "SOME_FLAG",
          s(:test,
            s(:object, "test2"))))

  end

  it "should combine adjacent nodes based on a volatile flag, if the first node cannot modify the flag" do
    volatile :my_flag
    # This section should combine, since does not contain any tests
    if_flag :my_flag do
      bin 1
    end
    unless_flag :my_flag do
      bin 2
    end
    test :test1
    # This section should not combine, since does contain a tests which could potentially
    # change the state of the flag
    if_flag :my_flag do
      test :test1
    end
    unless_flag :my_flag do
      bin 2
    end

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:volatile,
          s(:flag, "my_flag")),
        s(:if_flag, "my_flag",
          s(:set_result, "fail",
            s(:bin, 1)),
          s(:else,
            s(:set_result, "fail",
              s(:bin, 2)))),
        s(:test,
          s(:object, "test1")),
        s(:if_flag, "my_flag",
          s(:test,
            s(:object, "test1"))),
        s(:unless_flag, "my_flag",
          s(:set_result, "fail",
            s(:bin, 2))))
  end
end
