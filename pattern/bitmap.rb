# Pattern to exercise the keep alive of a pattern that needs reburst
Pattern.create(end_in_ka: true) do

  ss 'Dummy write reg'
  $dut.reg(:testme32).write!(0xFFFFFFFF)
  
end
