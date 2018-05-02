# coding: utf-8
config = File.expand_path('../config', __FILE__)
require "#{config}/version"

Gem::Specification.new do |spec|
  spec.name          = "origen_testers"
  spec.version       = OrigenTesters::VERSION
  spec.authors       = ["Stephen McGinty"]
  spec.email         = ["stephen.f.mcginty@gmail.com"]
  spec.summary       = "This plugin provides Origen tester models to drive ATE type testers like the J750, UltraFLEX, V93K,..."
  spec.homepage      = "http://origen-sdk.org/testers"

  spec.required_ruby_version     = '>= 2'

  # Only the files that are hit by these wildcards will be included in the
  # packaged gem, the default should hit everything in most cases but this will
  # need to be added to if you have any custom directories
  spec.files         = Dir["lib/**/*.rb", "lib/**/*.erb", "templates/**/*", "config/**/*.rb",
                           "bin/*", "lib/tasks/**/*.rake", "pattern/**/*.rb",
                           "program/**/*.rb"
                          ]
  spec.executables   = []
  spec.require_paths = ["lib"]

  # Add any gems that your plugin needs to run within a host application
  spec.add_runtime_dependency 'origen', '>= 0.26.0'
  spec.add_runtime_dependency 'require_all', '~> 1'
  spec.add_runtime_dependency 'atp', '~> 1.1', '>= 1.1.1'
end
