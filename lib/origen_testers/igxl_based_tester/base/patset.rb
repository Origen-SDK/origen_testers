module Testers
  module IGXLBasedTester
    class Base
      class Patset
        attr_accessor :index

        # Specify multiple patterns by passing an array of attributes
        # as the 2nd argument:
        #
        #   Patset.new("mrd1_pset", :pattern => "nvm_mrd1.PAT")
        #
        #   Patset.new("mrd1_pset", [{:pattern => "nvm_mrd1.PAT"},
        #                            {:pattern => "nvm_global_subs.PAT, :start_label => "subr"}
        #                           ])
        def initialize(name, attrs = {})
          attrs = [attrs] unless attrs.is_a? Array
          attrs.each do |pattrs|
            if pattrs[:pattern]
              pat = Pathname.new(pattrs[:pattern].gsub('\\', '/')).basename('.*').to_s
              Origen.interface.referenced_patterns << pat
            end
            lines << platform::PatsetPattern.new(name, pattrs)
          end
          self.name = name
        end

        def ==(other_patset)
          self.class == other_patset.class &&
            name.to_s == other_patset.name.to_s &&
            sorted_pattern_files == other_patset.sorted_pattern_files
        end

        def name
          @name
        end

        def name=(n)
          @name = n
          lines.each { |l| l.pattern_set = n }
          n
        end

        # Returns all lines in the pattern set
        def lines
          @lines ||= []
        end

        # Returns all pattern files in the pattern set in alphabetical order
        def sorted_pattern_files
          @lines.map(&:file_name).sort
        end

        # Returns the fully formatted pattern set for insertion into a patset sheet
        def to_s
          l = ''
          lines.each do |line|
            l += "#{line}\r\n"
          end
          l.chomp
        end

        def platform
          Origen.interface.platform
        end
      end
    end
  end
end
