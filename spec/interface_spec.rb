require 'spec_helper'

describe "An interface" do

  class MyInterface
    include OrigenTesters::ProgramGenerators

    def initialize(options = {})
      self.resources_filename = "abc"
    end
  end

  before :each do
    Origen.file_handler.current_file = Pathname.new("#{Origen.root}/spec/interface_spec")
  end

  it "resources_filename can be set from an interface initialize" do
    Origen.app.unload_target!
    Origen.target.temporary = "debug_ultraflex"
    # Ugly hack, should add a proper API for this, though it should only
    # ever be needed in a test situation
    Origen.instance_variable_set("@interface", nil)
    Flow.create interface: "MyInterface" do
      Origen.interface.test_instances_filename.should == "abc"
    end
  end
end
