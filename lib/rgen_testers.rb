require 'rgen'
require 'active_support/concern'
require 'require_all'

module Testers
  autoload :VectorBasedTester, 'testers/vector_based_tester'
  autoload :Vector,            'testers/vector'
  autoload :VectorPipeline,    'testers/vector_pipeline'
  autoload :Interface,         'testers/interface'
  autoload :Generator,         'testers/generator'
  autoload :Parser,            'testers/parser'
  autoload :BasicTestSetups,   'testers/basic_test_setups'
  autoload :ProgramGenerators, 'testers/program_generators'
  # not yet autoload :Time,    'testers/time'
end

require 'testers/igxl_based_tester'
require 'testers/smartest_based_tester'
require 'testers/pattern_compilers'

require 'testers/callback_handlers'
require_relative '../config/application.rb'
require_relative '../config/environment.rb'
