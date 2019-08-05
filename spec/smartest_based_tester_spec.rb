require 'spec_helper'

describe "Smartest Based Tester" do

  def with_open_flow(options={})
    Origen.target.temporary = -> do
      MyDUT.new
      if options.has_key?(:target_option)
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

end

