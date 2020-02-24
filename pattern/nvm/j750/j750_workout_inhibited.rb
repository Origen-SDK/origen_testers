Pattern.sequence skip_startup: true do |seq|
  tester.set_timeset('nvmbist', 40)
  tester.inhibit_vectors_and_comments do
    seq.run :j750_workout
  end
end
