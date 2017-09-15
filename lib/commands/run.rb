require 'optparse'
require 'pathname'

options = {}

opt_parser = OptionParser.new do |opts|
  opts.banner = <<-EOT
Run (execute a flow) of the last test program generated for the given target.

Usage: origen testers:run FLOW [options]
  EOT
  opts.on('--enable FLAG,FLAG', Array, 'Comma-separated list of flow flags to enable') { |flags| options[:flow_flags] = flags }
  opts.on('--job NAME', String, 'Job name to enable') { |job| options[:job] = job }
  opts.on('--fail ID,ID', Array, 'Comma-separated list of test IDs to fail') { |ids| options[:failed_test_ids] = ids }
  opts.on('-e', '--environment NAME', String, 'Override the default environment, NAME can be a full path or a fragment of an environment file name') { |e| options[:environment] = e }
  opts.on('-t', '--target NAME', String, 'Override the default target, NAME can be a full path or a fragment of a target file name') { |t| options[:target] = t }
  opts.on('-d', '--debugger', 'Enable the debugger') {  options[:debugger] = true }
  opts.on('-m', '--mode MODE', Origen::Mode::MODES, 'Force the Origen operating mode:', '  ' + Origen::Mode::MODES.join(', ')) { |_m| }
  opts.separator ''
  opts.on('-h', '--help', 'Show this message') { puts opts; exit 0 }
end

opt_parser.parse! ARGV

Origen.environment.temporary = options[:environment] if options[:environment]
Origen.target.temporary = options[:target] if options[:target]
# Origen.app.load_target!

program =  OrigenTesters.program

unless program
  puts 'Sorry, but there is no program model available for the current target, generate the program then retry'
  exit 1
end

unless ARGV.first
  if OrigenTesters.program.flows.keys.size == 1
    ARGV << OrigenTesters.program.flows.keys.first
  else
    puts 'You must supply the name of the flow to execute, the current program has these flows'
    puts OrigenTesters.program.flows.keys
    exit 1
  end
end

ARGV.each do |flow|
  OrigenTesters.program.flows[flow.to_sym].run(options)
end
