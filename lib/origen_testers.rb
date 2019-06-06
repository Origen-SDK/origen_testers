require 'origen'
require_relative '../config/application.rb'

require 'active_support/concern'
require 'require_all'
require 'atp'
require 'pathname'
require 'origen_testers/origen_ext/generator/pattern'
require 'origen_testers/origen_ext/generator/flow'
require 'origen_testers/origen_ext/generator/resources'
require 'origen_testers/origen_ext/application/runner'
require 'origen_testers/origen_ext/generator'

module OrigenTesters
  autoload :CommandBasedTester, 'origen_testers/command_based_tester'
  autoload :VectorBasedTester,  'origen_testers/vector_based_tester'
  autoload :Vector,             'origen_testers/vector'
  autoload :VectorPipeline,     'origen_testers/vector_pipeline'
  autoload :Interface,          'origen_testers/interface'
  autoload :Generator,          'origen_testers/generator'
  autoload :Parser,             'origen_testers/parser'
  autoload :BasicTestSetups,    'origen_testers/basic_test_setups'
  autoload :ProgramGenerators,  'origen_testers/program_generators'
  autoload :Flow,               'origen_testers/flow'
  autoload :NoInterface,        'origen_testers/no_interface'
  autoload :MemoryStyle,        'origen_testers/memory_style'

  # not yet autoload :Time,     'origen_testers/time'

  # The documentation tester model has been removed, but this keeps some
  # legacy code working e.g. $tester.is_a?(OrigenTesters::Doc)
  class Doc
  end

  def self.program
    f = "#{Flow::PROGRAM_MODELS_DIR}/#{Origen.target.name}"
    if File.exist?(f)
      ATP::Program.load(f)
    end
  end

  require 'origen_testers/decompiler'
  extend Decompiler::API
end

require 'origen_testers/igxl_based_tester'
require 'origen_testers/smartest_based_tester'
require 'origen_testers/labview_based_tester'
require 'origen_testers/pattern_compilers'
require 'origen_testers/pattern_compilers/runner'

require 'origen_testers/callback_handlers'
require 'origen_testers/origen_ext/pins/pin'
require 'origen_testers/origen_ext/pins/pin_collection'
require 'origen_testers/origen_ext/pins/timing'
require 'origen_testers/origen_ext/pins/timing/timeset'
