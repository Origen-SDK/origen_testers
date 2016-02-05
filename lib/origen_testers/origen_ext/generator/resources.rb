require 'origen/generator/resources'
module Origen
  class Generator
    class Resources
      alias_method :orig_create, :create

      # Patching to make resources_mode apply much earlier
      def create(options = {}, &block)
        OrigenTesters::Interface.with_resources_mode do
          orig_create(options, &block)
        end
      end
    end
  end
end
