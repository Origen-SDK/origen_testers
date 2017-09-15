require 'spec_helper'
module UFlexGenerator
  class Interface
    include Origen::TopLevel
    include OrigenTesters::ProgramGenerators

    def initialize
      # nothing to initialize
    end
  end

  describe 'UFlex Pinmap Sheet Generator' do
    it 'Adding pins, groups, power pins and virtual pins' do
      Origen.environment.temporary = "uflex"
      Origen.load_target("dut.rb")
      pinmap = Origen.interface.pinmaps('pinmap_name')
      pinmap.add_pin(:pin1, type: 'I/O', comment: 'comment1')
      pinmap.add_pin(:pin2, type: 'I', comment: 'comment2')
      pinmap.add_pin(:pin3, type: 'O', comment: 'comment3')
      pinmap.add_pin(:pin4, type: 'I/O', comment: 'comment4')
      pinmap.add_pin(:pin5, type: 'I/O', comment: 'comment5')
      pinmap.add_pin(:pin6, type: 'I/O', comment: 'comment6')
      pinmap.add_group_pin(:pin_grp1, :pin1, type: 'I/O', comment: 'comment1')
      pinmap.add_group_pin(:pin_grp1, :pin2, type: 'I/O', comment: 'comment2')
      pinmap.add_group_pin(:pin_grp1, :pin3, type: 'I/O', comment: 'comment3')
      pinmap.add_group_pin(:pin_grp1, :pin4, type: 'I/O', comment: 'comment4')
      pinmap.add_group_pin(:pin_grp2, :pin5, type: 'I/O', comment: 'comment5')
      pinmap.add_group_pin(:pin_grp2, :pin6, type: 'I/O', comment: 'comment6')
      pinmap.add_power_pin(:avdd, type: 'Power', comment: 'commenta')
      pinmap.add_power_pin(:bvdd, type: 'Power', comment: 'commentb')
      pinmap.add_power_pin(:cvdd, type: 'Power', comment: 'commentc')
      pinmap.add_utility_pin(:utility1, type: 'Utility', comment: 'comment1')
      pinmap.add_utility_pin(:utility2, type: 'I/O', comment: 'comment2')

      $tester.name.should == 'ultraflex'
      pinmap.platform.should == OrigenTesters::IGXLBasedTester::UltraFLEX
      pinmap.pins.size.should == 6
      pinmap.pin_groups.size.should == 2
      pinmap.power_pins.size.should == 3
      pinmap.utility_pins.size.should == 2

      pinmap.pins[:pin1][:type].should == 'I/O'
      pinmap.pins[:pin3][:type].should == 'O'
      pinmap.pins[:pin2][:comment].should == 'comment2'
      pinmap.pins[:pin4][:comment].should == 'comment4'

      pinmap.pin_groups[:pin_grp1][:pin3][:type].should == 'I/O'
      pinmap.pin_groups[:pin_grp2][:pin5][:comment].should == 'comment5'

      pinmap.power_pins[:avdd][:type].should == 'Power'
      pinmap.power_pins[:cvdd][:comment].should == 'commentc'

      pinmap.utility_pins[:utility1][:type].should == 'Utility'
      pinmap.utility_pins[:utility2][:type].should == 'I/O'
      pinmap.utility_pins[:utility2][:comment].should == 'comment2'
    end
  end
end
