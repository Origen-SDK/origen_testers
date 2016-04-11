module OrigenTesters
  module IGXLBasedTester
    class Base
      class References
        include ::OrigenTesters::Generator
        attr_accessor :references

        OUTPUT_PREFIX = nil
        OUTPUT_POSTFIX = nil

        def initialize # :nodoc:
          @references = []
        end

        def add(reference, options = {})
          options = {
            comment: nil
          }.merge(options)

          @references << { ref: reference, comment: options[:comment] }
        end
      end
    end
  end
end
