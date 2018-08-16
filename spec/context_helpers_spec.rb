require 'spec_helper'

describe 'The test context helpers' do
  OrigenTesters::V93K.new
  include OrigenTesters::ProgramGenerators

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

  it 'context_changed? works' do
    r = []
    if context_changed?
      r << 1
    end
    test :test1
    if context_changed?(if_enable: :blah)
      r << 2
    end
    test :test1, if_enable: :blah
    if context_changed?
      r << 3
    end
    test :test1
    if context_changed?
      r << 4
    end
    test :test1
    if_enable :blah do
      # Should be true since now in a block
      if context_changed?
        r << 5
      end
      test :test1
    end
    # Should also be true since now outside the block
    if context_changed?
      r << 6
    end
    test :test1
    r.should == [2,3,5,6]
  end

  it 'parameter_changed? works' do
    r = []
    if parameter_changed?(:vdd)
      r << 1
    end
    test :test1
    if parameter_changed?(:vdd, vdd: :min)
      r << 2
    end
    test :test1, vdd: :min
    if parameter_changed?(:vdd, vdd: :min)
      r << 3
    end
    test :test1, vdd: :min
    if parameter_changed?(:vdd, vdd: :max)
      r << 4
    end
    test :test1, vdd: :max
    if parameter_changed?(:vdd)
      r << 5
    end
    test :test1

    r.should == [2,4,5]
  end

  it 'context_or_parameter_changed? works' do
    r = []
    test :test1, vdd: :min, id: :t1
    if context_or_parameter_changed?(:vdd, vdd: :min)
      r << 1
    end
    test :test1, vdd: :min
    if context_or_parameter_changed?(:vdd)
      r << 2
    end
    test :test1
    if context_or_parameter_changed?(:vdd)
      r << 3
    end
    test :test1
    if context_or_parameter_changed?(:vdd, if_failed: :t1)
      r << 4
    end
    test :test1, if_failed: :t1

    r.should == [2,4]
  end
end
