Flow.create do |options|

  # Added set-flag to test that manually set flags are brought up to the top-level for SMT8
  func :margin_read1_all1, number: options[:number], on_fail: { set_flag: :ers_vfy_failed }

end
