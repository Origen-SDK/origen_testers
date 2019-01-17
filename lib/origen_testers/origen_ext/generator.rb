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
