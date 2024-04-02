require 'spec_helper'

describe "Smartest Based Tester" do

  def with_open_flow(options={})
    Origen.target.temporary = -> do
      MyDUT.new
      if options.has_key?(:smt8)
        OrigenTesters::V93K.new smt_version: 8
      elsif options.has_key?(:target_option)
        OrigenTesters::V93K.new unique_test_names: options[:target_option]
      else
        OrigenTesters::V93K.new
      end
    end
    # Create a dummy file for the V93K interface to use. Doesn't need to exists, it won't actually be used, just needs to be set.
    Origen.file_handler.current_file = Pathname.new("#{Origen.root}/temp.rb")
    Origen.load_target

    Origen.interface.try(:reset_globals)
    Origen.instance_variable_set("@interface", nil)
    if options.has_key?(:flow_option)
      Flow.create interface: 'MyInterface', unique_test_names: options[:flow_option] do
        yield
      end
    else
      Flow.create interface: 'MyInterface' do
        yield
      end
    end
    Origen.instance_variable_set("@interface", nil)
  end

  def interface
    Origen.interface
  end

  class MyDUT
    include Origen::TopLevel
  end

  class MyInterface
    include OrigenTesters::ProgramGenerators

    def yo
      :hi
    end

    def new_test(name, options={})
      if options.has_key?(:unique_test_names)
        self.unique_test_names = options[:unique_test_names]
      end
      test_suites.add(name, options)
    end

    def hash_test(name, options={})
      tm = test_methods.my_hash_tml.my_hash_test
      tm.hashParameter = options
      ts = test_suites.run(name, options)
      ts.test_method = tm
      ts.lines
    end
  end

  
  it "Filename method works for test_suites and test_methods" do
    with_open_flow do
      interface.yo.should == :hi
      interface.test_suites.filename.should == 'temp.tf'
      interface.test_methods.filename.should == 'temp.tf'
    end
  end

  it "Testsuite methods execute correctly" do
    with_open_flow target_option: nil do
      tester.unique_test_names.should == nil
      interface.new_test(:blah).name.should == :blah

      interface.test_suites.sorted_collection.each do |test_suite|
        test_suite.inspect.should == "<TestSuite: blah>"

        lambda { test_suite.name = 'different_blah' }.should raise_error
      end
    end
  end

  it "Hash parameter raised errors correctly" do
    with_open_flow smt8: true do
      interface.hash_test(:hash_test, {my_param_name: { param_name0: 1 }})
      lambda { interface.hash_test(:hash_test, {my_param_name: { fake_param: 1 }}) }.should raise_error
      lambda { interface.hash_test(:hash_test, 1) }.should raise_error
      lambda { interface.hash_test(:hash_test, {paramName1: 1, param_name1: 2}) }.should raise_error
      lambda { interface.hash_test(:hash_test, {my_param_name: {paramName1: 1, param_name1: 2} }) }.should raise_error
    end
    # Reset the environment for future specs
    with_open_flow target_option: nil do
    end
  end

  it "Auxiliary flows raise errors correctly" do
    with_open_flow smt8: true do
      lambda { interface.add_auxiliary_flow(:POWERDOWN, 'testflow') }.should raise_error
    end
    # Reset the environment for future specs
    with_open_flow target_option: nil do
    end
    with_open_flow do
      lambda { interface.add_auxiliary_flow(:POWERDOWN, 'testflow.POWERDOWN') }.should raise_error
    end
  end
end
