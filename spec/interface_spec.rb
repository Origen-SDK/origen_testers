require 'spec_helper'

describe "An interface" do

  class MyDUT
    include Origen::TopLevel
  end

  class MyInterface
    include OrigenTesters::ProgramGenerators
    include Origen::Callbacks

    def initialize(options = {})
      self.resources_filename = "abc"
      add_my_tml if tester.smt8?
    end

    def on_my_callback
      $_test_var += 1
    end

    def add_my_tml
      add_tml :my_hash_tml,
        class_name:      'MyTmlHashNamespace',

        # Here is a test definition.
        # The identifier should be lower-cased and underscored, in-keeping with Ruby naming conventions.
        # By default the class name will be the camel-cased version of this identifier, so 'myTest' in
        # this case.
        my_hash_test: {
          # [OPTIONAL] The C++ test method class name can be overridden from the default like this:
          class_name:   'MyHashExampleClass',
          # [OPTIONAL] If the test method does not require a definition in the testmethodlimits section
          #    of the .tf file, you can suppress like this:
          test_name: [:string, 'HashExample'],
          # In cases where the C++ library has deviated from standard attribute naming conventions
          # (camel-cased with lower cased first character), the absolute attribute name can be given
          # as a string.
          # The Origen accessor for these will be the underscored version, with '.' characters
          # converted to underscores e.g. tm.an_unusual_name
          'hashParameter':  [{param_name0: [:string, 'NO'], paramName1: [:integer, 0]}]
        } 
    end
  end

  before :each do
    # Ugly hack, should add a proper API for this, though it should only
    # ever be needed in a test situation
    Origen.instance_variable_set("@interface", nil)
    Origen.file_handler.current_file = Pathname.new("#{Origen.root}/spec/interface_spec")
  end

  after :all do
    # Ugly hack, should add a proper API for this, though it should only
    # ever be needed in a test situation
    Origen.instance_variable_set("@interface", nil)
  end

  it "resources_filename can be set from an interface initialize" do
    Origen.environment.temporary = "uflex.rb"
    Origen.load_target("dut.rb")
    Flow.create interface: "MyInterface" do
      Origen.interface.test_instances_filename.should == "abc"
    end
  end

  it "interface methods can be accessed outside of a flow" do
    Origen.file_handler.current_file = nil
    Origen.reset_interface
  end

  it "interfaces can include callbacks" do
    Origen.app.unload_target!
    Origen.target.temporary = -> do
      MyDUT.new
      OrigenTesters::V93K.new
    end
    Origen.target.load!

    Flow.create interface: "MyInterface" do
      $_test_var = 0
      Origen.listeners_for(:on_my_callback).each { |l| l.on_my_callback } 
      $_test_var.should == 1
      # Test that the interface remains registered during a sub-flow
      Flow.create do
        # Verify that the listening object is the current interface instance
        Origen.interface.object_id.should == Origen.app.instantiated_callback_listeners.first.object_id
        Origen.listeners_for(:on_my_callback).each { |l| l.on_my_callback } 
        $_test_var.should == 2
      end
    end

    # Run again, this is to make sure the previous interface is de-registered
    # properly and it does not hang around to increment this variable twice
    Flow.create interface: "MyInterface" do
      $_test_var = 0
      Origen.listeners_for(:on_my_callback).each { |l| l.on_my_callback } 
      $_test_var.should == 1
    end
  end
end

describe "An interface that does not want the target re-loaded" do

  class InterfaceThatLikesSpeed
    include OrigenTesters::ProgramGenerators

    attr_accessor :reload_target

    def initialize(options = {})
      @reload_target = false
    end
  end

  before :each do
    # Ugly hack, should add a proper API for this, though it should only
    # ever be needed in a test situation
    Origen.instance_variable_set("@interface", nil)
    Origen.file_handler.current_file = Pathname.new("#{Origen.root}/spec/interface_spec")
  end

  after :all do
    # Ugly hack, should add a proper API for this, though it should only
    # ever be needed in a test situation
    Origen.instance_variable_set("@interface", nil)
    Origen.target.temporary = nil
    Origen.app.unload_target!
  end

  it "Target is only loaded once during flow generation" do
    Origen.environment.temporary = "uflex.rb"
    Origen.load_target("dut.rb")
    dut.target_load_count.should == 1
    Flow.create interface: 'InterfaceThatLikesSpeed' do
      dut.target_load_count.should == 1
    end
    dut.target_load_count.should == 1
    # The interface wins the day over any flow file settings
    Flow.create interface: 'InterfaceThatLikesSpeed', reload_target: true do
      dut.target_load_count.should == 1
    end
    dut.target_load_count.should == 1
  end
end

