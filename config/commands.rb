# This file should be used to extend the origen command line tool with tasks 
# specific to your application.
# The comments below should help to get started and you can also refer to
# lib/origen/commands.rb in your Origen core workspace for more examples and 
# inspiration.
#
# Also see the official docs on adding commands:
#   http://origen.freescale.net/origen/latest/guides/custom/commands/

# Map any command aliases here, for example to allow origen -x to refer to a 
# command called execute you would add a reference as shown below: 
aliases = {
#  "-x" => "execute",
  "g"  => "generate"
}

# The requested command is passed in here as @command, this checks it against
# the above alias table and should not be removed.
@command = aliases[@command] || @command

# Now branch to the specific task code
case @command

# Generates a pattern model given the input file(s).
when "generate_pattern_model"
  Origen.load_target
  approved = ARGV.delete('--approve')
  ARGV.each do |pat|
    puts "Generating pattern model for #{pat}"
    model = OrigenTesters::Decompiler.decompile(pat)
    path = model.write_spec_yaml(approved: approved)
    puts "Wrote model to: #{path}"
    puts
  end
  exit 0

when "analyze_decompiler_performance", 'analyze_decomp_perf' 

  envs = {
    j750: {output: "#{Origen.app!.root}/output/j750/pin_flip.atp", count_scale: 1.0},
    v93k: {output: "#{Origen.app!.root}/output/v93k/pin_flip.avc", count_scale: 1.0},
    stil: {output: "#{Origen.app!.root}/output/stil/pin_flip.stil", count_scale: 1.0},
  }

  opt_parser = OptionParser.new do |opts|
    opts.banner = 'Run a performance test for the available decompilers.'
    opts.on('-c', '--count COUNT', Integer, 'Overrides the full-toggle count (vectors = 2 * count)') { |c| options[:count] = c }
    opts.on('-s', '--scale SCALE', Float, 'Overrides the default scale of 1.0 for all decompilers') do |s|
      envs.each { |e, o| o[:count_scale] *= s }
    end
    opts.on('-e', '--environment NAME', String, 'Override the default environment, NAME can be a full path or a fragment of an environment file name') { |e| options[:environment] = e }
    opts.on('-t', '--target NAME', String, 'Override the default target, NAME can be a full path or a fragment of a target file name') { |t| options[:target] = t }
    opts.on('-p', '--pin NAME', String, 'Override the default pin for toggling. Default is \'tclk\'') { |t| options[:pin] = t }

    envs.each do |env, o|
      opts.on("--#{env}_scale SCALE", Float, "Additinally scales the #{env} platform") { |s| envs[env][:count_scale] *= s }
    end

    opts.separator ''
    opts.on('-h', '--help', 'Show this message') { puts opts; exit 0 }
  end
  opt_parser.parse! ARGV
  
  Origen.log.info "Testing Decompiler Performance..."
  Origen.log.info "Performing setup..."

  Origen.target.temporary = options[:target] || 'default'
  Origen.load_target
  ENV['ORIGEN_TESTERS_BIT_FLIP_PIN'] = options[:pin] || 'tclk'

  Origen.log.info
  Origen.log.info "Generating pattern 'pin_flip' toggling pin #{ENV['ORIGEN_TESTERS_BIT_FLIP_PIN']}..."

  count = options[:count] || 10_000
  envs.each do |e, opts|
    env_count = (opts[:count_scale] * count).to_i.to_s
    Origen.log.info "  Generating pattern for environment: #{e}.rb... "
    Origen.log.info "    Target Count: #{env_count}"

    ENV['ORIGEN_TESTERS_BIT_FLIP_COUNT'] = env_count
    Origen.environment.temporary = "#{e}.rb"
    Origen.app.runner.generate(patterns: 'pin_flip')
  end
  
  target_env = options[:environment] || 'v93k.rb'
  Origen.log.info
  Origen.log.info "Conversion Target Env: #{target_env}"
  Origen.log.info "Converting Patterns..."
  fields = {'User Time' => 0, 'System time' => 1, 'Elapsed Time' => 3, 'Peak Memory Usage' => 8}
  resource_usages = {}
  maxes = fields.map { |k, v| [k, [0.0, nil]] }.to_h
  mins = fields.map { |k, v| [k, [Float::INFINITY, nil]] }.to_h
  envs.each do |env, opts|
    usage = {}
    cmd = "/usr/bin/time -v origen convert #{opts[:output]} -e #{target_env} -o #{Origen.app!.root}/output/performance_test/#{env}"
    out, err, stat = Open3.capture3(cmd)
    output = err.split("\n")
    fields.each do |f, i|
      if f == 'Elapsed Time'
        t = Time.parse("0:#{output[i+1].split(': ').last}")
        usage[f] = ((t.min * 60) + t.sec).to_f
      else
        usage[f] = output[i+1].split(': ').last.to_f
      end
      if usage[f] > maxes[f][0]
        maxes[f] = [usage[f], env]
      end
      if usage[f] < mins[f][0]
        mins[f] = [usage[f], env]
      end
    end
    
    resource_usages[env] = usage
    puts out
    puts err
  end
  
  Origen.log.info
  Origen.log.info "Usage Report:"
  Origen.log.info "Count Scales:"
  envs.each do |env, opts|
    Origen.log.info "  #{env}: #{opts[:count_scale]} (#{opts[:count_scale] * count.to_i})"
  end
  Origen.log.info "File sizes:"
  envs.each do |env, opts|
    Origen.log.info "  #{opts[:output]}: %.2f MiB" % (File.size(opts[:output]).to_f / 2**20)
  end
  fields.keys.each do |f|
    Origen.log.info "  #{f}:"
    Origen.log.info "    Max:  #{maxes[f][0]} (#{maxes[f][1]})"
    Origen.log.info "    Min:  #{mins[f][0]} (#{mins[f][1]})"
    s = '%.2f' % (maxes[f][0] - mins[f][0])
    Origen.log.info "    Diff Max-to-Min: #{s}"
    s = '%.2f' % ((mins[f][0] / maxes[f][0]) * 100)
    Origen.log.info "    Scale Max-to-Min: #{s}%"
    s = '%.2f' % ((maxes[f][0] / mins[f][0]) * 100)
    Origen.log.info "    Scale Min-to-Max: #{s}%"
  end

  exit 0

when "tags"
  Dir.chdir Origen.root do
    system "ripper-tags --recursive lib"
  end
  exit 0

# Run the unit tests  
when "specs"
  require "rspec"
  exit RSpec::Core::Runner.run(['spec'])

# Run the example-based (diff) tests
when "examples", "test"
  Origen.load_application
  status = 0

  Dir["#{Origen.root}/examples/*.rb"].each do |example|
    require example
  end

  # Compiler tests
#    ARGV = %w(templates/example.txt.erb -t debug -r approved)
#    load "origen/commands/compile.rb"
  if Origen.app.stats.changed_files == 0 &&
    Origen.app.stats.new_files == 0 &&
    Origen.app.stats.changed_patterns == 0 &&
    Origen.app.stats.new_patterns == 0

    Origen.app.stats.report_pass
  else

    puts
    puts "To approve any diffs in the reference.list files run the following command:"
    puts
    puts "cp list/j750/referenced.list approved/j750/referenced.list && cp list/j750_hpt/referenced.list approved/j750_hpt/referenced.list && cp list/ultraflex/referenced.list approved/ultraflex/referenced.list && cp list/v93k/referenced.list approved/v93k/referenced.list"
    puts
    Origen.app.stats.report_fail
    status = 1
  end
  puts
  if @command == "test"
    Origen.app.unload_target!
    require "rspec"
    result = RSpec::Core::Runner.run(['spec'])
    status = status == 1 ? 1 : result
  end
  exit status  # Exit with a 1 on the event of a failure per std unix result codes

# Always leave an else clause to allow control to fall back through to the
# Origen command handler.
# You probably want to also add the command details to the help shown via
# origen -h, you can do this be assigning the required text to @application_commands
# before handing control back to Origen. Un-comment the example below to get started.
else
  @application_commands = <<-EOT
 specs        Run the specs (tests), -c will enable coverage
 examples     Run the examples (tests), -c will enable coverage
 test         Run both specs and examples, -c will enable coverage
 tags         Generate ctags for this app 
  EOT

end 
