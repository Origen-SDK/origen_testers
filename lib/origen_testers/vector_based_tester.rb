require 'active_support/concern'
module OrigenTesters
  # Including this module in a class gives it all the basics required
  # to generator vector-based test patterns
  module VectorBasedTester
    extend ActiveSupport::Concern

    require 'origen_testers/vector_generator'
    require 'origen_testers/timing'
    require 'origen_testers/api'

    included do
      include VectorGenerator
      include Timing
      include API
    end

    module ClassMethods # :nodoc:
      # This overrides the new method of any class which includes this
      # module to force the newly created instance to be registered as
      # a tester with Origen
      def new(*args, &block) # :nodoc:
        if Origen.app.with_doc_tester?
          x = OrigenTesters::Doc.allocate
          if Origen.app.with_html_doc_tester?
            x.html_mode = true
          end
        else
          x = allocate
        end
        x.send(:initialize, *args, &block)
        x.register_tester
        x
      end
    end

    def register_tester # :nodoc:
      Origen.app.tester = self
    end
  end
end
