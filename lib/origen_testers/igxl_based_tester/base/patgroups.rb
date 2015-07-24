module OrigenTesters
  module IGXLBasedTester
    class Base
      class Patgroups
        include ::OrigenTesters::Generator

        OUTPUT_POSTFIX = 'patgroups'

        def add(name, options = {})
          p = platform::Patgroup.new(name, options)
          collection << p
          p
        end

        def finalize(options = {})
          uniq!
          sort!
        end

        # Present the patgroups in the final sheet in alphabetical order
        def sort!
          collection.sort_by!(&:name)
        end

        # Removes all duplicate patgroups
        def uniq!
          uniques = []
          collection.each do |patgroup|
            unless uniques.any? { |p| p == patgroup }
              uniques << patgroup
            end
          end
          self.collection = uniques
        end
      end
    end
  end
end
