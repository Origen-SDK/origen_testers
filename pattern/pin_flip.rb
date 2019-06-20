Pattern.create do
  ENV['ORIGEN_TESTERS_BIT_FLIP_COUNT'].to_i.times do |i|
    if i % 2 == 0
      dut.pins(ENV['ORIGEN_TESTERS_BIT_FLIP_PIN'].to_sym).drive!(0)
    else
      dut.pins(ENV['ORIGEN_TESTERS_BIT_FLIP_PIN'].to_sym).drive!(1)
    end
  end
end
