# Program generator tests
%w(j750 j750_hpt ultraflex v93k).each do |platform|
  ARGV = ["program/prod.list", "-t", "debug_#{platform}.rb", "-r", "approved/#{platform}"]
  load 'rgen/commands/program.rb'
end
