Pattern.create do
  tester.push_stil_header('Ann{* STIL Header Test *}') if tester.respond_to?(:push_stil_header)
end
