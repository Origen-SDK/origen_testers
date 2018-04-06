# This shim is temporary to help NXP transition to Origen from
# our original internal version (RGen)
if defined? RGen::ORIGENTRANSITION
  require 'rgen/generator'
else
  require 'origen/generator'
end
module Origen
  class Generator
    include Comparator

    # @api private
    def generate_sub_program(file, options)
      @generated_sub_programs ||= {}
      # Generate the sub flow in a forked process, allowing us to replace the current top-level
      # flow with a new one in the fork
      reader, writer = IO.pipe
      reader.binmode
      writer.binmode
      pid = fork do
        Origen.app.stats.reset_global_stats
        OrigenTesters::Flow.flow_comments = nil # Stop it going down the sub-flow branch in Flow.create
        # If we are already in a sub-program and about to create a sub-flow from that...
        if @output_dir
          @output_dir = File.join(@output_dir, File.basename(Origen.interface.flow.filename, '.*').to_s.downcase)
        else
          @output_dir = File.join(Origen.interface.flow.output_file.dirname, File.basename(Origen.interface.flow.filename, '.*').to_s.downcase)
        end
        Origen.reset_interface({ interface: Origen.interface.class.to_s }.merge(options))
        Origen.interface.reset_globals # Get rid of all already generated content, the parent process will handle those
        Origen.interface.clear_pattern_references
        Origen.generator.generate_program(file, action: :program, skip_referenced_pattern_write: true, skip_on_program_completion: true) do
          Origen.interface.flow.output_directory = @output_dir
          # When the same sub flow is called/generated twice give it a unique name since different options
          # could have been passed into the import statement in the flow
          if @generated_sub_programs[Origen.interface.flow.output_file]
            i = 1
            while @generated_sub_programs[Origen.interface.flow.output_file]
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
        return_data[:changed_files] = Origen.app.stats.changed_files
        return_data[:new_files] = Origen.app.stats.new_files
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
      @generated_sub_programs[return_data[:file]] = true
      Origen.interface.merge_pattern_references(return_data[:pattern_references])
      basedir = Pathname.new(Origen.app.config.test_program_output_directory || Origen.app.config.output_directory)
      path = Pathname.new(return_data[:file]).relative_path_from(basedir)
      Origen.interface.flow.atp.sub_flow(return_data[:nodes], path: path.to_s)
      Origen.app.stats.changed_files += return_data[:changed_files]
      Origen.app.stats.new_files += return_data[:new_files]
      Origen.app.stats.completed_files += (return_data[:new_files] || return_data[:changed_files])
    end

    # @api private
    # Makes more sense for this plugin to own this method now
    def generate_program(file, options)
      Origen.file_handler.resolve_files(file, ignore_with_prefix: '_', default_dir: "#{Origen.root}/program") do |path|
        Origen.file_handler.current_file = path
        j = Job.new(path, options)
        j.pattern = path
        j.run
      end
      yield if block_given?
      Origen.interface.write_files(options)
      unless options[:quiet] || !Origen.interface.write? || options[:skip_referenced_pattern_write]
        if options[:referenced_pattern_list]
          file = "#{Origen.root}/list/#{options[:referenced_pattern_list]}"
        else
          file = Origen.config.referenced_pattern_list
        end
        Origen.log.info "Referenced pattern list written to: #{Pathname.new(file).relative_path_from(Pathname.pwd)}"
        dir = Pathname.new(file).dirname
        FileUtils.mkdir_p(dir) unless dir.exist?
        File.open(file, 'w') do |f|
          pats = Origen.interface.all_pattern_references.map do |name, refs|
            refs[:main][:all] + refs[:main][:origen]
          end.flatten.uniq.sort
          unless pats.empty?
            f.puts '# Main patterns'
            pats.each { |p| f.puts p }
            f.puts
          end

          pats = Origen.interface.all_pattern_references.map do |name, refs|
            refs[:subroutine][:all] + refs[:subroutine][:origen]
          end.flatten.uniq.sort
          unless pats.empty?
            f.puts '# Subroutine patterns'
            pats.each { |p| f.puts p }
          end
        end
        ref_file = File.join(Origen.file_handler.reference_directory, Pathname.new(file).basename)
        check_for_changes(file, ref_file)
      end
      Origen.interface.on_program_completion(options) unless options[:skip_on_program_completion]
    end
  end
end
