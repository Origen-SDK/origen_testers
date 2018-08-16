require 'spec_helper'

describe 'The test context helpers' do
  it 'context_changed? works' do
    with_open_flow do |i,f|
      r = []
      if i.context_changed?
        r << 1
      end
      i.test :test1
      if i.context_changed?(if_enable: :blah)
        r << 2
      end
      i.test :test1, if_enable: :blah
      if i.context_changed?
        r << 3
      end
      i.test :test1
      if i.context_changed?
        r << 4
      end
      i.test :test1
      i.if_enable :blah do
        # Should be true since now in a block
        if i.context_changed?
          r << 5
        end
        i.test :test1
      end
      # Should also be true since now outside the block
      if i.context_changed?
        r << 6
      end
      i.test :test1
      r.should == [2,3,5,6]
    end
  end

  it 'parameter_changed? works' do
    with_open_flow do |i,f|
      r = []
      if i.parameter_changed?(:vdd)
        r << 1
      end
      i.test :test1
      if i.parameter_changed?(:vdd, vdd: :min)
        r << 2
      end
      i.test :test1, vdd: :min
      if i.parameter_changed?(:vdd, vdd: :min)
        r << 3
      end
      i.test :test1, vdd: :min
      if i.parameter_changed?(:vdd, vdd: :max)
        r << 4
      end
      i.test :test1, vdd: :max
      if i.parameter_changed?(:vdd)
        r << 5
      end
      i.test :test1

      r.should == [2,4,5]
    end
  end

  it 'context_or_parameter_changed? works' do
    with_open_flow do |i,f|
      r = []
      i.test :test1, vdd: :min, id: :t1
      if i.context_or_parameter_changed?(:vdd, vdd: :min)
        r << 1
      end
      i.test :test1, vdd: :min
      if i.context_or_parameter_changed?(:vdd)
        r << 2
      end
      i.test :test1
      if i.context_or_parameter_changed?(:vdd)
        r << 3
      end
      i.test :test1
      if i.context_or_parameter_changed?(:vdd, if_failed: :t1)
        r << 4
      end
      i.test :test1, if_failed: :t1

      r.should == [2,4]
    end
  end
end
