Flow.create do |options|

  func :pgm_ckbd, number: options[:number] + 10
  func :mrd_ckbd, number: options[:number] + 20

end
