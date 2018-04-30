# Program generator tests
%w(j750 j750_hpt ultraflex v93k).each do |platform|
  files = []
  files << "program/prod.list"
  files << "program/uflex_resources.rb" if platform == 'ultraflex'
  ARGV = [*files, "-t", "dut.rb", "-e", "#{platform}.rb", "-r", "approved/#{platform}"]
  load 'origen/commands/program.rb'
  FileUtils.mkdir_p "#{Origen.root}/list/#{platform}"
  FileUtils.mv "#{Origen.root}/list/referenced.list", "#{Origen.root}/list/#{platform}/referenced.list"
end

# Tests of the V93K flow enable/disable options
ARGV = ["program/prb1.rb", "program/prb2.rb", "-t", "dut.rb", "-e", "v93k_enable_flows.rb", "-r", "approved/v93k_enable_flow",
        "-o", "#{Origen.root}/output/v93k_enable_flow"]
load 'origen/commands/program.rb'
ARGV = ["program/prb1.rb", "program/prb2.rb", "-t", "dut.rb", "-e", "v93k_disable_flows.rb", "-r", "approved/v93k_disable_flow",
        "-o", "#{Origen.root}/output/v93k_disable_flow"]
load 'origen/commands/program.rb'

# Test for V93K - multiport
ARGV = ["program/prb1.rb", "-t", "dut4.rb", "-e", "v93k.rb", "-r", "approved/v93k_multiport", "-o", "#{Origen.root}/output/v93k_multiport"]
load 'origen/commands/program.rb'
FileUtils.mkdir_p "#{Origen.root}/list/v93k_multiport"
FileUtils.mv "#{Origen.root}/list/referenced.list", "#{Origen.root}/list/v93k_multiport/referenced.list"

# Tests of the V93K unique test name options

