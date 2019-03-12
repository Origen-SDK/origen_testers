case @command

when "convert"
  require "#{Origen.root!}/lib/commands/convert"
  exit 0

else
  @global_commands << <<-EOT
 convert      Convert a tester pattern from one format to another
  EOT

end
