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
      # Generate the sub flow in a forked process, allowing us to replace the current top-level
      # flow with a new one in the fork
      read, write = IO.pipe
      pid = fork do
        OrigenTesters::Flow.flow_comments = nil # Stop it going down the sub-flow branch in Flow.create
        output_dir = File.join(Origen.interface.flow.output_file.dirname, File.basename(Origen.interface.flow.filename, '.*'))
        Origen.interface.reset_globals # Get rid of all already generated content, the parent process will handle those
        Origen.interface.clear_pattern_references
        Origen.generator.generate_program(file, action: :program, skip_referenced_pattern_write: true, skip_on_program_completion: true) do
          Origen.interface.flow.output_directory = output_dir
        end
        return_data = {}
        return_data[:pattern_references] = Origen.interface.all_pattern_references
        Marshal.dump(return_data, write)
        exit!(0) # Skips exit handlers
      end
      # Block until the fork finishes, let's keep the generation order sequential
      Process.wait(pid)
      write.close
      return_data = Marshal.load(read.read)
      read.close
      Origen.interface.merge_pattern_references(return_data[:pattern_references])
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
