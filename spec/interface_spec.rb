require 'spec_helper'

describe "An interface" do

  class MyInterface
    include Testers::ProgramGenerators

    def initialize(options = {})
      self.resources_filename = "abc"
    end
  end

  before :each do
    Origen.file_handler.current_file = Pathname.new("#{Origen.root}/spec/interface_spec")
  end

  it "resources_filename can be set from an interface initialize" do
    load_target "debug_ultraflex"
    Flow.create interface: "MyInterface" do
      Origen.interface.test_instances_filename.should == "abc"
    end
  end
end
