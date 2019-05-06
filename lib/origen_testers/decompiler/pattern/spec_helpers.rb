module OrigenTesters
  module Decompiler
    class Pattern
      module SpecHelpers
        def to_yaml_hash(options = {})
          {
            pattern:     @path,
            timestamp:   Time.now.to_s,
            class:       self.class.to_s,
            # ... Add in the variables here

            frontmatter: frontmatter.to_yaml_hash,
            pinlist:     pinlist.to_yaml_hash,
            vectors:     collect_vectors { |v, i| v.to_yaml_hash }
          }
        end

        def to_spec_yaml(options = {})
          to_yaml_hash.to_yaml
        end
        
        def spec_yaml_output
          "#{Origen.app!.root}/output/#{platform}/decompiler/models/#{source.basename}.yaml"
        end
        
        def spec_yaml_approved
          "#{Origen.app!.root}/approved/#{platform}/decompiler/models/#{source.basename}.yaml"
        end

        def write_spec_yaml(options = {})
          path = options[:approved] ? spec_yaml_approved : spec_yaml_output
          unless Dir.exist?(File.dirname(path))
            FileUtils.mkdir_p(File.dirname(path))
          end
          File.open(path, 'w').puts(to_spec_yaml(options))
          path
        end
      end
    end
  end
end
