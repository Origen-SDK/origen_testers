require 'origen'
require 'active_support/concern'
require 'require_all'

module OrigenTesters
  autoload :Doc,                'origen_testers/doc'
  autoload :CommandBasedTester, 'origen_testers/command_based_tester'
  autoload :VectorBasedTester,  'origen_testers/vector_based_tester'
  autoload :Vector,             'origen_testers/vector'
  autoload :VectorPipeline,     'origen_testers/vector_pipeline'
  autoload :Interface,          'origen_testers/interface'
  autoload :Generator,          'origen_testers/generator'
  autoload :Parser,             'origen_testers/parser'
  autoload :BasicTestSetups,    'origen_testers/basic_test_setups'
  autoload :ProgramGenerators,  'origen_testers/program_generators'

  # not yet autoload :Time,     'origen_testers/time'
end

require 'origen_testers/igxl_based_tester'
require 'origen_testers/smartest_based_tester'
require 'origen_testers/pattern_compilers'

require 'origen_testers/callback_handlers'
require_relative '../config/application.rb'
require 'origen_testers/origen_ext/pins/pin'
require 'origen_testers/origen_ext/pins/pin_collection'
