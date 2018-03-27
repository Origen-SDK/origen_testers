Flow.create do |options|

  if_enable 'additional_erase', :or => options[:force] do
    func :erase_all, number: options[:number]
  end

end
