module OrigenTesters
  module IGXLBasedTester
    class Base
      class Patsubrs
        include ::OrigenTesters::Generator

        OUTPUT_POSTFIX = 'patsubrs'

        def add(name, options = {})
          p = Patsubr.new(name, options)
          collection << p
          p
        end

        def finalize(options = {})
          uniq!
          sort!
        end

        # Present the patsubrs in the final sheet in alphabetical order
        def sort!
          collection.sort_by!(&:name)
        end

        # Removes all duplicate patsubrs
        def uniq!
          uniques = []
          collection.each do |patsubr|
            unless uniques.any? { |p| p == patsubr }
              uniques << patsubr
            end
          end
          self.collection = uniques
        end
      end
    end
  end
end
