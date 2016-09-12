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
    end

    def on_my_callback
      $_test_var += 1
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
    Origen.app.unload_target!
    Origen.target.temporary = "debug_ultraflex"
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
