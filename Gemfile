source 'https://rubygems.org'

# Development dependencies
gem 'byebug', "~>11" if RUBY_VERSION < "4" # byebug C extension doesn't compile on Ruby 4.0+

# Stdlib gems extracted from the default gems in Ruby 4.0; needed by activesupport/nanoc.
if RUBY_VERSION >= '4'
  gem 'fiddle', '~> 1'
  gem 'pstore'
  gem 'mutex_m'
  gem 'benchmark'
end
gem 'ripper-tags'
gem 'origen_arm_debug', '0.4.3'
gem 'yard-activesupport-concern'
gem 'origen_jtag', '>= 0.12.0'
gem 'origen_doc_helpers'

# Gem version constraints for testing with Ruby 2.3
gem 'nokogiri' # No more restricting to 1.10.10 as ruby 2.3 is not supported
gem 'dry-inflector', '0.1.2'
gem 'rubyzip', '~>1'

gem 'origen_stil', git: "https://github.com/Origen-SDK/origen_stil.git"
gem 'origen', '>= 0.61.3'
# Specify all runtime dependencies in origen_testers.gemspec
gemspec
