require 'spec_helper'

module ATEHardwareSpec
  class ATEHardwareDUT
    # include OrigenTesters::IGXLBasedTester::UltraFLEX::ATEHardware
    include Origen::TopLevel

    def initialize
      # nothing to initialize
    end
  end

  describe 'ATEHardware Tester Modeling' do
    Origen.target.temporary = 'ultraflex_atehardware'
    Origen.app.load_target!
    $dut = ATEHardwareDUT.new
    Origen.tester.import_tester_config('FT', "#{Origen.root}/spec/atehardware/CurrentConfig_sample.txt")
    Origen.tester.import_chanmap('FTx4', "#{Origen.root}/spec/atehardware/atehardware_chanmap.txt")
    $dut.add_pin :pin1
    $dut.add_pin :pin2
    $dut.add_pin :pin3
    $dut.add_pin :k1
    $dut.add_power_pin_group :avdd

    it 'Importing UltraFLEX tester config properly' do
      $tester.name.should == 'ultraflex'
      $tester.default_testerconfig.should == 'FT'
      $tester.get_tester_instrument('FT', 1).should == 'HSD-4G'
      $tester.get_instrument_slots('FT', 'HSD-U').should == [12, 14, 15, 17, 20]
    end
    it 'Importing UltraFLEX channelmap properly' do
      $tester.default_channelmap.should == 'FTx4'
      $tester.get_tester_channel('FTx4', :pin1, 0).should == '14.ch28'
      $tester.get_tester_channel('FTx4', :pin2, 3).should == '20.ch231'
      $tester.channelmap['FTx4'].size.should == 4
      $tester.merged_channels('FTx4', :avdd, 1).should == 'x2'
      $tester.is_hexvs_plus('FT', 18).should == '+'
      $tester.is_vhdvs_plus('FT', 0).should == '+'
      $tester.is_vhdvs_hc('FTx4', :cvdd, 2).should == '_HC'
    end
    it 'Loading and Retrieving ATEHardware data properly' do
      $tester.ate_hardware('VSMx2').supply.irange.max.should == 162
      $dut.pins(:pin1).ate_hardware.instrument.should == 'HSD-U'
      $dut.pins(:pin1).ate_hardware.ppmu.forcei.max.should == 0.05
      $dut.pins(:k1).instrument_type.instrument.should == 'SupportBoard'
      $dut.power_pin_groups(:avdd).ate_hardware.instrument.should == 'VHDVS_HC+x2'
      $dut.power_pin_groups(:avdd).ate_hardware.supply.forcev.cover?(4).should == true
    end
  end
end
