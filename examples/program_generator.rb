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

# Test for DUT4 for V93K - multiport, smartbuild, limits file, vars file and pattern compiler updates.
ARGV = ["program/prod.list", "-t", "dut4.rb", "-e", "v93k.rb", "-r", "approved/v93k_dut4", "-o", "#{Origen.root}/output/v93k_dut4"]
load 'origen/commands/program.rb'
FileUtils.mkdir_p "#{Origen.root}/list/v93k_dut4"
FileUtils.mv "#{Origen.root}/list/referenced.list", "#{Origen.root}/list/v93k_dut4/referenced.list"

# Tests of the V93K unique test name options

