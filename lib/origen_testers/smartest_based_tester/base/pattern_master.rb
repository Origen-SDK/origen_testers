require 'pathname'
module OrigenTesters
  module SmartestBasedTester
    class Base
      class PatternMaster
        include OrigenTesters::Generator

        attr_reader :flow, :paths
        attr_accessor :filename, :id

        def initialize(flow = nil)
          @flow = flow
          @paths = {}
        end

        def filename
          @filename || flow.filename.sub('.tf', '.pmfl')
        end

        def subdirectory
          'vectors'
        end

        def paths
          { '../vectors' => patterns }
        end

        # def add(name, options = {})
        #  name, subdir = extract_subdir(name, options)
        #  name += '.binl.gz' unless name =~ /binl.gz$/
        #  # Don't want to ask Origen to compile these, but do want them in the v93k
        #  # compile list
        #  if name =~ /_part\d+\.binl\.gz$/
        #    Origen.interface.pattern_compiler.part_patterns << name
        #  else
        #    Origen.interface.referenced_patterns << name
        #  end
        #  paths[subdir] ||= []
        #  # Just add it, duplicates will be removed at render time
        #  paths[subdir] << name unless paths[subdir].include?(name)
        # end

        def patterns
          return_arr = (references[:subroutine][:all] + references[:subroutine][:ate] +
            references[:main][:all] + references[:main][:ate]).map do |p|
            p = p.strip
            p += '.binl.gz' unless p =~ /binl.gz$/
          end.uniq
          if $tester.multiport
            return_arr += (references[:main][:all] + references[:main][:ate]).map do |p|
              p = p.strip
              p += "_#{$tester.multiport_ext}.binl.gz" unless p =~ /_#{$tester.multiport_ext}.binl.gz$/
            end.uniq
          end
          return_arr
        end

        def references
          Origen.interface.all_pattern_references[id]
        end

        private

        def extract_subdir(name, options = {})
          p = Pathname.new(name.to_s)
          name = p.basename.to_s
          subdir = p.dirname.to_s
          # if subdir == '.'
          #  # In future may support setting a default subdir via the interface
          # end
          [name, subdir]
        end
      end
    end
  end
end
