Flow.create do |options|

  func :pgm_ckbd, number: options[:number] + 10
  func :mrd_ckbd, number: options[:number] + 20

  self.include_additional_prb2_test = true

end
