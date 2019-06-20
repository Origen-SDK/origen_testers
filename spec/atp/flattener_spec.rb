require 'spec_helper'

describe 'The Flattener (and his friends)' do
  include OrigenTesters::ATP::FlowAPI

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  def ast(options = {})
    options = {
      add_ids: false,
      optimization: :flat,
    }.merge(options)
    atp.ast(options)
  end

  it "flattens flag conditions and removes redundancies" do
    test :test1
    test :test2, if_flag: :f1
    if_flag :f1 do
      test :test3
      test :test4, if_flag: :f1
      test :test5, if_flag: :f2
    end

    atp.raw.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1")),
        s(:if_flag, "f1",
          s(:test,
            s(:object, "test2"))),
        s(:if_flag, "f1",
          s(:test,
            s(:object, "test3")),
          s(:if_flag, "f1",
            s(:test,
              s(:object, "test4"))),
          s(:if_flag, "f2",
            s(:test,
              s(:object, "test5")))))

    ast.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1")),
        s(:if_flag, "f1",
          s(:test,
            s(:object, "test2"))),
        s(:if_flag, "f1",
          s(:test,
            s(:object, "test3"))),
        s(:if_flag, "f1",
          s(:test,
            s(:object, "test4"))),
        s(:if_flag, "f1",
          s(:if_flag, "f2",
            s(:test,
              s(:object, "test5")))))
  end

  it "preserves groups" do
    test :test1, id: :t1
    if_failed :t1 do
      group "my_group", id: :g1 do
        test :test2
        test :test3
      end
      test :test4
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1")),
        s(:if_failed, "t1",
          s(:group,
            s(:name, "my_group"),
            s(:id, "g1"),
            s(:test,
              s(:object, "test2")),
            s(:test,
              s(:object, "test3"))),
          s(:test,
            s(:object, "test4"))))

    ast.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1")),
        s(:group,
          s(:name, "my_group"),
          s(:id, "g1"),
          s(:if_failed, "t1",
            s(:test,
              s(:object, "test2"))),
          s(:if_failed, "t1",
            s(:test,
              s(:object, "test3")))),
        s(:if_failed, "t1",
          s(:test,
            s(:object, "test4"))))

  end

  it "else nodes are converted to the equivalent inverse parent node" do
    test :test1, id: :t1
    if_enabled "bitmap", then: -> do
      test :test2
    end, else: -> do
      test :test3, if_failed: :t1
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1)),
        s(:if_enabled, "bitmap",
          s(:test,
            s(:object, "test2")),
          s(:else, 
            s(:if_failed, :t1,
              s(:test,
                s(:object, "test3"))))))

    ast.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, :t1)),
        s(:if_enabled, "bitmap",
          s(:test,
            s(:object, "test2"))),
        s(:unless_enabled, "bitmap",
          s(:if_failed, :t1,
            s(:test,
              s(:object, "test3")))))
  end

  it "converts most things in on_pass fail to the equivalent if_failed/passed node" do
    test :test1, on_fail: -> do
      test :test2
      bin 5
    end, 
    on_pass: -> do
      test :test3
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:on_fail,
            s(:test,
              s(:object, "test2")),
            s(:set_result, "fail",
              s(:bin, 5))),
          s(:on_pass,
            s(:test,
              s(:object, "test3")))))

    ast(add_ids: true).should == 
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t3")),
        s(:if_failed, "t3",
          s(:test,
            s(:object, "test2"),
            s(:id, "t1"))),
        s(:if_failed, "t3",
          s(:set_result, "fail",
            s(:bin, 5))),
        s(:if_passed, "t3",
          s(:test,
            s(:object, "test3"),
            s(:id, "t2"))))
  end
end
