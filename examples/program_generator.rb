# Program generator tests
%w(j750 j750_hpt ultraflex v93k).each do |platform|
  ARGV = ["program/prod.list", "-t", "debug_#{platform}.rb", "-r", "approved/#{platform}"]
  load 'origen/commands/program.rb'
end
