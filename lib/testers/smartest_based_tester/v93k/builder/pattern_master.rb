module Testers
  module SmartestBasedTester
    class V93K
      class Builder
        # Responsible for modelling/building the contents of a V93K pattern master file
        class PatternMaster
          attr_reader :file, :paths

          def initialize(file = nil)
            @file = file
            @paths = {}
            parse_file if file
          end

          def add_sub_file(pm)
            pm.paths.each do |path, files|
              if paths[path]
                paths[path] += files
                paths[path].uniq!
              else
                paths[path] = files
              end
            end
          end

          private

          def parse_file
            File.open(file) do |f|
              capture = nil
              current_path = nil
              f.each_line do |line|
                line = line.strip
                if line =~ /^\s*path:\s*$/
                  capture = :path
                elsif capture == :path
                  paths[line] ||= []
                  current_path = paths[line]
                  capture = nil
                elsif line =~ /^\s*files:\s*$/
                  capture = :file
                elsif capture == :file
                  unless line.empty?
                    current_path << line
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
