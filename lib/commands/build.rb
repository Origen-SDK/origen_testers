require 'optparse'
require 'pathname'

options = {}

opt_parser = OptionParser.new do |opts|
  opts.banner = <<-EOT
Build a test program from a collection of sub-programs.

The user must supply a manifest file to define the test program's flows. Each flow definition will state
which sub-program modules that the flow is comprised of, and the order in which they should be executed.
The manifest file is written in YAML format and a new manifest file can be generated for the current target
tester by running the command with the --new option.

Upon launch the command will parse all of the sub-program files into memory. It will then combine and render
them out to new files, making edits on the fly where necessary to enable the sub-programs to co-exist within
the same test program.
The generated files can be tracked and diff-checked by Origen in the usual way.

Usage: origen testers:build MANIFEST [options]
  EOT
  opts.on('-e', '--environment NAME', String, 'Override the default environment, NAME can be a full path or a fragment of an environment file name') { |e| options[:environment] = e }
  opts.on('-t', '--target NAME', String, 'Override the default target, NAME can be a full path or a fragment of a target file name') { |t| options[:target] = t }
  opts.on('-pl', '--plugin PLUGIN_NAME', String, 'Set current plugin') { |pl_n|  options[:current_plugin] = pl_n }
  opts.on('-d', '--debugger', 'Enable the debugger') {  options[:debugger] = true }
  opts.on('-m', '--mode MODE', Origen::Mode::MODES, 'Force the Origen operating mode:', '  ' + Origen::Mode::MODES.join(', ')) { |_m| }
  opts.on('-n', '--new', 'Generate a new manifest file for the current tester platform') { options[:new] = true }
  opts.on('-o', '--output DIR', String, 'Override the default output directory') { |o| options[:output] = o }
  opts.on('-r', '--reference DIR', String, 'Override the default reference directory') { |o| options[:reference] = o }
  opts.separator ''
  opts.on('-h', '--help', 'Show this message') { puts opts; exit 0 }
end

opt_parser.parse! ARGV

Origen.load_application
Origen.current_plugin.temporary = options[:current_plugin] if options[:current_plugin]
Origen.environment.temporary = options[:environment] if options[:environment]
Origen.target.temporary = options[:target] if options[:target]
Origen.app.load_target!

manifest = ARGV.first

unless manifest
  puts 'You must supply a path to a manifest file'
  exit 1
end
unless $tester.v93k?
  puts "Sorry but the #{$tester.name} tester is not yet supported by the build command :-("
  exit 1
end

if options[:new]
  template = "#{Origen.root!}/templates/manifest/#{$tester.name}.yaml.erb"
  manifest += '.yaml' unless manifest =~ /\..*/

  Origen.app.runner.launch action:            :compile,
                         files:             template,
                         output:            Pathname.new(manifest).dirname.to_s,
                         output_file_name:  Pathname.new(manifest).basename.to_s,
                         quiet:             true,
                         check_for_changes: false

  puts "New #{$tester.name} manifest created: #{manifest}"
  exit 0
end

# Ideally should auto select the correct test platform here, for now hardcoding to V93K
eval("#{$tester.class}::Builder").new.build(manifest, options)
