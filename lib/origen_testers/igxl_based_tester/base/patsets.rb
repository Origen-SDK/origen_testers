module OrigenTesters
  module IGXLBasedTester
    class Base
      class Patsets
        include ::OrigenTesters::Generator

        OUTPUT_POSTFIX = 'patsets'

        def add(name, options = {})
          p = platform::Patset.new(name, options)
          collection << p
          p
        end

        def finalize(options = {})
          uniq!
          sort!
        end

        # Present the patsets in the final sheet in alphabetical order
        def sort!
          collection.sort_by!(&:name)
        end

        # Removes all duplicate patsets
        def uniq!
          uniques = []
          collection.each do |patset|
            unless uniques.any? { |p| p == patset }
              uniques << patset
            end
          end
          self.collection = uniques
        end
      end
    end
  end
end
