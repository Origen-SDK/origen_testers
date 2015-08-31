# Pattern to exercise the reading and writing of a register using ARM Debug
Pattern.create do
  ss 'Test write register with all 1s'
  $dut.reg(:testme32).write!(0xFFFFFFFF)
  ss 'Test read register after all 1s write'
  $dut.reg(:testme32).read!

  ss 'Test write register with all 0s'
  $dut.reg(:testme32).write!(0x00000000)
  ss 'Test read register after all 0s write'
  $dut.reg(:testme32).read!

  ss 'Test store register, the whole register data should be stored'
  $dut.reg(:testme32).store!

  ss 'Test store bits, only enable bit should be captured'
  $dut.reg(:testme32).bit(:enable).store!

  ss 'Test store bits, only port A should be captured'
  $dut.reg(:testme32).bits(:portA).store!

  ss 'Test read of partial register, only portA should be read'
  $dut.reg(:testme32).bits(:portB).read!

  ss 'Test overlay, all reg vectors should be from subroutine'
  $dut.reg(:testme32).overlay('write_overlay')
  $dut.reg(:testme32).write!

  ss 'Test overlay, same again but for read'
  $dut.reg(:testme32).overlay('read_overlay')
  $dut.reg(:testme32).read!

  ss 'Test bit level write overlay, only portA should be from subroutine'
  $dut.reg(:testme32).overlay(nil)  # have to reset overlay bits as they are sticky from last overlay set
  $dut.reg(:testme32).bits(:portA).overlay('write_overlay')
  $dut.reg(:testme32).bits(:portA).write!

  ss 'Test bit level read overlay, only portA should be from subroutine'
  $dut.reg(:testme32).overlay(nil)
  $dut.reg(:testme32).bits(:portA).overlay('read_overlay')
  $dut.reg(:testme32).bits(:portA).read!

  ss 'Call execute subroutine'
  $dut.execute

  ss 'Call match_pin subroutine'
  $dut.match(:type => :match_pin)

  ss 'Call match_2pins subroutine'
  $dut.match(:type => :match_2pins)

  ss 'Call match_done subroutine'
  $dut.match(:type => :match_done)

  ss 'Call handshake subroutine'
  $dut.handshake

end
