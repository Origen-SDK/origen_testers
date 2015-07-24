module OrigenTesters
  module SmartestBasedTester
    class V93K
      # Responsible for building V93K test programs from a collection of sub-programs
      class Builder
        require 'yaml'

        autoload :Flow, 'origen_testers/smartest_based_tester/v93k/builder/flow'
        autoload :PatternMaster, 'origen_testers/smartest_based_tester/v93k/builder/pattern_master'

        attr_reader :manifest

        def build(manifest, options = {})
          @manifest_dir = Pathname.new(manifest).dirname.to_s
          @manifest = YAML.load_file(manifest).with_indifferent_access
          parse_sub_programs
          render(options)
        end

        private

        def render(options)
          manifest[:flows].each do |name, flow|
            flow_file = nil
            pm_file = nil

            flow.each do |sub_program|
              unless flows[sub_program]
                puts "Flow #{name} includes sub-program #{sub_program}, but it has not been defined!"
                exit 1
              end
              flow_file ||= Flow.new
              flow_file.add_sub_flow(flows[sub_program])
              if pattern_masters[sub_program]
                pm_file ||= PatternMaster.new
                pm_file.add_sub_file(pattern_masters[sub_program])
              end
            end

            compile_options = {
              action:           :compile,
              files:            "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k/templates/template.flow.erb",
              output_file_name: "#{name}.flow",
              output_sub_dir:   'testflow',
              options:          { program: flow_file }
            }.merge(options)

            Origen.app.runner.launch(compile_options)

            if pm_file
              compile_options = {
                action:           :compile,
                files:            "#{Origen.root!}/lib/origen_testers/smartest_based_tester/v93k/templates/template.pmfl.erb",
                output_file_name: "#{name}.pmfl",
                output_sub_dir:   'vectors',
                options:          { program: pm_file }
              }.merge(options)
            end
            Origen.app.runner.launch(compile_options)
          end
        end

        def parse_sub_programs
          manifest[:sub_programs].each do |sub_program|
            name = sub_program[:name]
            if sub_program[:flow]
              flows[name] = Flow.new(find_file(sub_program[:flow]))
            end
            if sub_program[:pattern_master]
              pattern_masters[name] = PatternMaster.new(find_file(sub_program[:pattern_master]))
            end
          end
        end

        def find_file(file)
          Origen.file_handler.clean_path_to(file, default_dir: @manifest_dir)
        end

        def flows
          @flows ||= {}
        end

        def pattern_masters
          @pattern_masters ||= {}
        end
      end
    end
  end
end
