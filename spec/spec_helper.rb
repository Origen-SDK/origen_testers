$VERBOSE=nil  # Don't care about world writable dir warnings and the like

require 'pathname'
require 'rubygems'
require 'bundler/setup'

require "origen"

require "rspec/legacy_formatters" if Gem::Version.new(RSpec::Core::Version::STRING) < Gem::Version.new('3.0.0')
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

def s(type, *children)
  OrigenTesters::ATP::AST::Node.new(type, children)
end

def to_ast(str)
  OrigenTesters::ATP::AST::Node.from_sexp(str)
end

def add_meta!(options)
  called_from = caller.find { |l| l =~ /_spec.rb:.*/ }
  if called_from
    called_from = called_from.split(':')
    if Origen.running_on_windows?
      options[:source_file] = "#{called_from[0]}:#{called_from[1]}"
      options[:source_line_number] = called_from[2].to_i
    else
      options[:source_file] = called_from[0]
      options[:source_line_number] = called_from[1].to_i
    end
  end
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
