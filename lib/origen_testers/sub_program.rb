module OrigenTesters
  class SubProgram
    attr_reader :file, :parent, :options

    def initialize(file, parent, options)
      @file, @parent, @options = file, parent, options
      @@generated_sub_programs ||= {}
      # Reference the output_dir to force it to resolve and cache before we switch files
      output_dir

      # These are for communication between the main process
      @reader, @writer = IO.pipe
      @reader.binmode
      @writer.binmode
    end

    def output_dir
      @output_dir ||= begin
        # If we are already in a sub-program and about to create a sub-flow from that...
        if parent
          File.join(parent.output_dir, File.basename(Origen.interface.flow.filename, '.*').to_s.downcase)
        else
          File.join(Origen.interface.flow.output_file.dirname, File.basename(Origen.interface.flow.filename, '.*').to_s.downcase)
        end
      end
    end

    def generate
      # Generate the sub flow in a forked process, allowing us to replace the current top-level
      # flow with a new one in the fork
      pid = fork do
        Origen.app.stats.reset_global_stats
        OrigenTesters::Flow.flow_comments = nil # Stop it going down the sub-flow branch in Flow.create
        Origen.interface.reset_globals # Get rid of all already generated content, the parent process will handle those
        Origen.interface.clear_pattern_references
        OrigenTesters::Interface.class_variable_set('@@generating_sub_program', true)
        Origen.generator.generate_program(file, action: :program, skip_referenced_pattern_write: true, skip_on_program_completion: true) do
          Origen.interface.flow.output_directory = output_dir
          # When the same sub flow is called/generated twice give it a unique name since different options
          # could have been passed into the import statement in the flow
          if @@generated_sub_programs[Origen.interface.flow.output_file]
            i = 1
            while @@generated_sub_programs[Origen.interface.flow.output_file]
              filename = Pathname.new(Origen.interface.flow.filename).basename('.*').to_s.sub(/_\d+$/, '')
              Origen.interface.flow.filename = "#{filename}_#{i}"
              i += 1
            end
          end
        end
        return_data = {}
        return_data[:pattern_references] = Origen.interface.all_pattern_references
        return_data[:nodes] = Origen.interface.flow.atp.raw
        return_data[:file] = Origen.interface.flow.output_file
        return_data[:completed_files] = Origen.app.stats.completed_files
        return_data[:changed_files] = Origen.app.stats.changed_files
        return_data[:new_files] = Origen.app.stats.new_files
        return_data[:instance_variables] = {}
        Origen.interface.instance_variables.each do |var|
          val = Origen.interface.instance_variable_get(var)
          exclude_vars = Array(Origen.interface.sub_flow_no_return_vars)
          exclude_vars << :@custom_tmls
          unless var == val.is_a?(Proc) || exclude_vars.include?(var)
            return_data[:instance_variables][var] = val
          end
        end
        if defined?(TestIds) && TestIds.configured?
          return_data[:test_ids] = TestIds.current_configuration.allocator.store
        end
        data = Marshal.dump(return_data)
        writer.puts(data.bytesize)
        writer.write(data)
        writer.close
        exit!(0) # Skips exit handlers
      end

      # Get the size of the return packet, this will block until the fork has the data ready
      size_in_bytes = reader.gets.strip.to_i
      data = reader.read(size_in_bytes)
      reader.close
      return_data = Marshal.load(data)
      @@generated_sub_programs[return_data[:file]] = true
      Origen.interface.merge_pattern_references(return_data[:pattern_references])
      TestIds.current_configuration.allocator.merge_store(return_data[:test_ids]) if return_data[:test_ids]
      path = Pathname.new(return_data[:file]).relative_path_from(Origen.file_handler.output_directory)
      Origen.interface.flow.atp.sub_flow(return_data[:nodes], path: path.to_s)
      Origen.app.stats.changed_files += return_data[:changed_files]
      Origen.app.stats.new_files += return_data[:new_files]
      Origen.app.stats.completed_files += return_data[:completed_files]
      return_data[:instance_variables].each do |var, value|
        Origen.interface.instance_variable_set(var, value)
      end
    end
  end
end
