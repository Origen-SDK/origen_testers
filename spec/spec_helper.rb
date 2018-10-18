$VERBOSE=nil  # Don't care about world writable dir warnings and the like

require 'pathname'
if File.exist? File.expand_path("../Gemfile", Pathname.new(__FILE__).realpath)
  require 'rubygems'
  require 'bundler/setup'
else
  # If running on windows, can't use Origen helpers 'till we load it...
  if RUBY_PLATFORM == 'i386-mingw32'
    `where origen`.split("\n").find do |match|
      match =~ /(.*)\\bin\\origen$/
    end
    origen_top = $1.gsub("\\", "/")
  else
    origen_top = `which origen`.strip.sub("/bin/origen", "")
  end

  $LOAD_PATH.unshift "#{origen_top}/lib"
end

require "origen"

require "rspec/legacy_formatters"
require "#{Origen.top}/spec/format/origen_formatter"

require "byebug"
require 'pry'
require 'origen_testers'

def load_target(target="default")
  Origen.target.switch_to target
  Origen.target.load!
end

def s(type, *children)
  ATP::AST::Node.new(type, children)
end

def to_ast(str)
  ATP::AST::Node.from_sexp(str)
end

class SpecInterface
  include OrigenTesters::ProgramGenerators
end

class SpecDUT
  include Origen::TopLevel
end

def with_open_flow(options={})
  options = {
    interface: 'SpecInterface',
    dut: 'SpecDUT',
    tester: 'V93K'
  }.merge(options)

  Origen.target.temporary = -> do
    eval(options[:dut]).new
    eval("OrigenTesters::#{options[:tester]}").new
  end
  # Create a dummy file for the V93K interface to use. Doesn't need to exists, it won't actually be used, just needs to be set.
  Origen.file_handler.current_file = Pathname.new("#{Origen.root}/temp.rb")
  Origen.load_target

  Origen.interface.try(:reset_globals)
  Origen.instance_variable_set("@interface", nil)
  Flow.create interface: options[:interface] do
    yield Origen.interface, Origen.interface.flow
  end
  Origen.instance_variable_set("@interface", nil)
end



RSpec.configure do |config|
  config.formatter = OrigenFormatter
  # config.filter_run :focus => true
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # Enable only the newer, non-monkey-patching expect syntax.
    # For more details, see:
    #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
    expectations.syntax = [:should, :expect]
  end
end
