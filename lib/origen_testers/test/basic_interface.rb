module OrigenTesters
  module Test
    # A simple interface designed to test the Testers::BasicTestSetups module
    class BasicInterface
      include OrigenTesters::BasicTestSetups

      def functional(name, options = {})
        # Apply custom defaults before calling
        options = {
          bin: 3
        }.merge(options)
        # Now call the generator
        super
      end
    end
  end
end
