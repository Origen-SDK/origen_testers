Pattern.create do |options|
  pat = OrigenTesters::Decompiler.decompile($DECOMPILE_PATTERN)
  pat.execute
end

