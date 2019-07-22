Flow.create do |options|

  if environment == :probe
    func :pgm_ckbd, number: options[:number] + 10
    func :mrd_ckbd, number: options[:number] + 20
  end

  self.include_additional_prb2_test = true

end
