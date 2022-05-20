# Program generator tests
{
  j750: ["program/prod.list"],
  j750_literals: ["program/flow_control_literals.rb"],
  j750_hpt: ["program/prod.list"],
  ultraflex: ["program/prod.list", "program/uflex_resources.rb"],
  ultraflex_literals: ["program/flow_control_literals.rb"],
  v93k: ["program/charz.rb", "program/prod.list"],
  v93k_multiport: ["program/prb1.rb"],
  v93k_enable_flow: ["program/prb1.rb", "program/prb2.rb"],
  v93k_disable_flow: ["program/prb1.rb", "program/prb2.rb"],
  v93k_limits_file: ["program/test.rb"],
  v93k_global: ["program/prb1.rb", "program/prb2.rb"],
  v93k_smt8: ["program/prod.list"],
}.each do |platform, files|
  ARGV = [*files, "-t", "dut.rb", "-e", "#{platform}.rb", "-r", "approved/#{platform}", "-o", "#{Origen.root}/output/#{platform}"]
  load 'origen/commands/program.rb'
  FileUtils.mkdir_p "#{Origen.root}/list/#{platform}"
  FileUtils.mv "#{Origen.root}/list/referenced.list", "#{Origen.root}/list/#{platform}/referenced.list"
end
