# Program generator tests
%w(j750 j750_hpt ultraflex v93k).each do |platform|
  files = []
  files << "program/prod.list"
  files << "program/uflex_resources.rb" if platform == 'ultraflex'
  ARGV = [*files, "-t", "debug_#{platform}.rb", "-r", "approved/#{platform}"]
  load 'origen/commands/program.rb'
  FileUtils.mkdir_p "#{Origen.root}/list/#{platform}"
  FileUtils.mv "#{Origen.root}/list/referenced.list", "#{Origen.root}/list/#{platform}/referenced.list"
end
