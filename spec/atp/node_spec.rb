require 'spec_helper'

describe 'AST Nodes' do

  it "can be exported to a string and back again" do
    node = 
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:name, "test1"),
          s(:id, :t1)),
        s(:flow_flag, "bitmap", true,
          s(:test,
            s(:name, "test2")),
          s(:test_result, :t1, false,
            s(:test,
              s(:name, "test3")))))
    OrigenTesters::ATP::AST::Node.from_sexp(node.to_sexp).to_sexp.should == node.to_sexp

    ast = to_ast <<-END
      (flow
        (name "sort1")
        (test
          (name "test1")
          (id "t1"))
        (flow-flag "bitmap" true
          (test
            (name "test2"))
          (test-result "t1" false
            (test
              (name "test3")))))
    END
    ast.to_sexp.should == node.to_sexp
  end



end
