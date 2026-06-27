require 'optparse'
require 'pathname'
require 'origen_testers'
require 'origen_stil'

options = {}

ENVIRONMENTS = {
  j750:      OrigenTesters::J750,
  uflex:     OrigenTesters::UltraFLEX,
  v93k_smt7: OrigenTesters::V93K
}.with_indifferent_access

opt_parser = OptionParser.new do |opts|
  if Origen.running_globally?
    opts.banner = <<-EOT
Convert the given pattern file to another environment (tester) format.

Usage: origen convert FILE -e v93k_smt7 [options]
  EOT
  else
    opts.banner = <<-EOT
Convert the given pattern file to another environment (tester) format.

Usage: origen convert FILE [options]
  EOT
  end
  opts.on('-o', '--output DIR', String, 'Override the default output directory') { |t| options[:output] = t }
  if Origen.running_globally?
    opts.on('-e', '--environment NAME', ENVIRONMENTS, 'Specify the target environment:', '  ' + ENVIRONMENTS.keys.join(', ')) { |e| options[:environment] = e }
  else
    opts.on('-e', '--environment NAME', String, 'Override the default environment, NAME can be a full path or a fragment of an environment file name') { |e| options[:environment] = e }
    opts.on('-t', '--target NAME', String, 'Override the default target, NAME can be a full path or a fragment of a target file name') { |t| options[:target] = t }
  end
  opts.on('-d', '--debugger', 'Enable the debugger') { options[:debugger] = true }
  opts.on('-m', '--mode MODE', Origen::Mode::MODES, 'Force the Origen operating mode:', '  ' + Origen::Mode::MODES.join(', ')) { |_m| }
  opts.separator ''
  opts.on('-h', '--help', 'Show this message') { puts opts; exit 0 }
end

opt_parser.parse! ARGV

if Origen.running_globally?

  module OrigenTesters
    class AnonymousDUT
      include Origen::TopLevel
    end
  end

  unless options[:environment]
    puts 'You must specify the target environment (tester) via the -e switch with one of the following values:'
    puts '  ' + ENVIRONMENTS.keys.join(', ')
    exit 1
  end

  Origen.target.temporary = lambda do
    OrigenTesters::AnonymousDUT.new
    options[:environment].new
    # Stops the generated pattern being compared to a reference
    tester.define_singleton_method(:disable_pattern_diffs) { true }
  end
else

  Origen.environment.temporary = options[:environment] if options[:environment]
  Origen.target.temporary = options[:target] if options[:target]
end

def converter(file, options = {})
  if OrigenTesters.decompiler_for?(file)
    lambda do
      OrigenTesters.execute(file)
    end
  else
    snippet = IO.read(file, 2000)  # Read first 2000 characters
    case snippet
    when /STIL \d+\.\d+/
      lambda do
        STIL.add_pins(file)
        # Use raw pin names in the output pattern and not the ALL pin group or similar, maybe
        # make this an option in future though
        dut.pin_pattern_order(*dut.pins.map { |id, pin| id })
        STIL.execute(file, set_timesets: true)
      end
    else
      Origen.log.error "Unknown input format for file: #{file}"
      nil
    end
  end
end

ARGV.each do |input|
  if c = converter(input)
    name = Pathname.new(input).basename('.*').to_s

    job = Origen::Generator::Job.new('anonymous', {})
    Origen.app.current_jobs << job
    if options[:output]
      FileUtils.mkdir_p(options[:output]) unless File.exist?(options[:output])
      job.instance_variable_set(:@output_pattern_directory, options[:output])
    end

    Origen.load_target

    Origen::Generator::Pattern.convert(input) do
      Pattern.create name: name do
        c.call
      end
    end
  end
end
