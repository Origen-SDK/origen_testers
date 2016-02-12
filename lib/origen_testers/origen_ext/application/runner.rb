# This shim is temporary to help NXP transition to Origen from
# our original internal version (RGen)
if defined? RGen::ORIGENTRANSITION
  require 'rgen/application/runner'
else
  require 'origen/application/runner'
end
module Origen
  class Application
    class Runner
      alias_method :orig_launch, :launch
      # Patch this to allow write: false to be given as an option when
      # generating a test program. When supplied and set to false, the program
      # output files will not be written and only a flow model will be generated.
      def launch(options = {})
        if options.key?(:write)
          OrigenTesters::Interface.write = options[:write]
        else
          OrigenTesters::Interface.write = true
        end
        orig_launch(options)
      end
    end
  end
end
