Pattern.create do
  tester.digital_instrument = 'hsdp' if tester.respond_to?(:digital_instrument)
end