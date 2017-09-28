require 'spec_helper'

describe "V93K unique test name generation" do

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

  it "The testbench is setup properly" do
    with_open_flow do
      interface.yo.should == :hi
    end
  end

  it "Appends a signature to test names by default" do
    with_open_flow do
      tester.unique_test_names.should == :signature
      interface.new_test(:blah).name.should == 'blah_F11FA85'
    end
  end

  it "Can be turned off at target-level" do
    with_open_flow target_option: nil do
      tester.unique_test_names.should == nil
      interface.new_test(:blah).name.should == :blah
    end
    with_open_flow target_option: false do
      tester.unique_test_names.should == false
      interface.new_test(:blah).name.should == :blah
    end
  end

  it "Can be set to use the flow name at target-level" do
    with_open_flow target_option: :flowname do
      tester.unique_test_names.should == :flowname
      interface.new_test(:blah).name.should == "blah_temp"
    end
    with_open_flow target_option: :flow_name do
      tester.unique_test_names.should == :flow_name
      interface.new_test(:blah).name.should == "blah_temp"
    end
  end

  it "Can be set to use a unique string at target-level" do
    with_open_flow target_option: :nvm1 do
      tester.unique_test_names.should == :nvm1
      interface.new_test(:blah).name.should == "blah_nvm1"
    end
    with_open_flow target_option: 'nvm2' do
      tester.unique_test_names.should == 'nvm2'
      interface.new_test(:blah).name.should == "blah_nvm2"
    end
  end

  it "Can be overridden at flow-level" do
    with_open_flow target_option: 'nvm2', flow_option: :flowname do
      interface.new_test(:blah).name.should == "blah_temp"
    end
    with_open_flow target_option: 'nvm2', flow_option: nil do
      interface.new_test(:blah).name.should == :blah
    end
  end

  it "Can be overridden at interface-level" do
    with_open_flow target_option: 'nvm2', flow_option: :flowname do
      interface.new_test(:blah, unique_test_names: nil).name.should == :blah
    end
  end
end
