require 'spec_helper'

describe 'v93k output directory specification' do
  before :each do
    Origen.instance_variable_set('@interface', nil)
  end

  after :all do
    Origen.instance_variable_set('@interface', nil)
  end

  class MyDUT
    include Origen::TopLevel
  end

  class MyInterface
    include OrigenTesters::ProgramGenerators
  end

  it 'Defaults to using v93k standard subdir if subdirectory instance variable is not set' do
    Origen.target.temporary = lambda do
      MyDUT.new
      OrigenTesters::V93K.new
    end
    # Create a dummy file for the V93K interface to use. Doesn't need to exists, it won't actually be used, just needs to be set.
    Origen.file_handler.current_file = Pathname.new("#{Origen.root}/temp.rb")
    Origen.load_target
    Flow.create interface: 'MyInterface' do
    end
    Origen.interface.flow.output_file.relative_path_from(Origen.root).to_s
      .should == 'output/v93k/testflow/mfh.testflow.group/temp.tf'
    Origen.interface.variables_file.output_file.relative_path_from(Origen.root).to_s
      .should == 'output/v93k/testflow/mfh.testflow.setup/abc_vars.tf'
    Origen.interface.pattern_master.output_file.relative_path_from(Origen.root).to_s
      .should == 'output/v93k/vectors/global.pmfl'
  end

  it 'Uses specified subdirectory in output_file' do
    Origen.target.temporary = lambda do
      MyDUT.new
      OrigenTesters::V93K.new
    end
    Origen.file_handler.current_file = Pathname.new("#{Origen.root}/temp.rb")
    Origen.load_target
    Flow.create interface: 'MyInterface' do
    end
    Origen.interface.flow.subdirectory = ''
    Origen.interface.variables_file.subdirectory = ''
    Origen.interface.pattern_master.subdirectory = ''
    Origen.interface.flow.output_file.relative_path_from(Origen.root).to_s
      .should == 'output/v93k/temp.tf'
    Origen.interface.variables_file.output_file.relative_path_from(Origen.root).to_s
      .should == 'output/v93k/abc_vars.tf'
    Origen.interface.pattern_master.output_file.relative_path_from(Origen.root).to_s
      .should == 'output/v93k/global.pmfl'
  end
end
