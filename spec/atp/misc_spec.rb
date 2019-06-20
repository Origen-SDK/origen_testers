require 'spec_helper'

describe 'Miscellaneous tests' do
  include OrigenTesters::ATP::FlowAPI

  before :each do
    self.atp = OrigenTesters::ATP::Program.new.flow(:sort1) 
  end

  it "immediate child nodes can be removed from an AST by type and object" do
    ast = 
      s(:flow,
        s(:name, "sort1"),
        s(:log, "Another group-level dependencies test based on a real life use case"),
        s(:test,
          s(:object, "gt1"),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 90))),
          s(:id, "t1")),
        s(:if_flag, "gt_grp2_FAILED",
          s(:test,
            s(:object, "gt3"),
            s(:id, "t7"))),
        s(:test,
          s(:object, "gt3"),
          s(:id, "t7")))

    ast.remove(:test, :log).should ==
       s(:flow,
         s(:name, "sort1"),
         s(:if_flag, "gt_grp2_FAILED",
           s(:test,
             s(:object, "gt3"),
             s(:id, "t7"))))

     log = ast.find(:log)
     if_flag = ast.find(:if_flag)

     ast.remove(log, if_flag).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "gt1"),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 90))),
          s(:id, "t1")),
        s(:test,
          s(:object, "gt3"),
          s(:id, "t7")))
  end

  it "nodes can be saved via Marshal and maintain meta data" do
    test :test1, on_fail: { bin: 5 }
    test :test2, on_fail: { bin: 6, continue: true }

    ast = atp.raw
    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 5)))),
        s(:test,
          s(:object, "test2"),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 6)),
            s(:continue))))

    ast.is_a?(OrigenTesters::ATP::AST::Node).should == true
    ast.find(:test).source.should include("misc_spec.rb:55")
    id = ast.id

    ast = Marshal.load(Marshal.dump(ast))
    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, {"Test"=>"test1", "Pattern"=>nil, "Test Name"=>"test1", "Sub Test Name"=>"test1"}),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 5)))),
        s(:test,
          s(:object, {"Test"=>"test2", "Pattern"=>nil, "Test Name"=>"test2", "Sub Test Name"=>"test2"}),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 6)),
            s(:continue))))

    ast.is_a?(OrigenTesters::ATP::AST::Node).should == true
    ast.find(:test).source.should include("misc_spec.rb:55")
    ast.id.should == id
  end




end
