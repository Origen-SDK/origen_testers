require 'pathname'
module Testers
  module SmartestBasedTester
    class Base
      class PatternMaster
        include Testers::Generator

        attr_reader :flow, :paths
        attr_accessor :filename

        def initialize(flow = nil)
          @flow = flow
          @paths = {}
        end

        def filename
          @filename || flow.filename.sub('.flow', '.pmfl')
        end

        def subdirectory
          'vectors'
        end

        def add(name, options = {})
          name, subdir = extract_subdir(name, options)
          name += '.binl.gz' unless name =~ /binl.gz$/
          RGen.interface.referenced_patterns << name
          paths[subdir] ||= []
          # Just add it, duplicates will be removed at render time
          paths[subdir] << name unless paths[subdir].include?(name)
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
