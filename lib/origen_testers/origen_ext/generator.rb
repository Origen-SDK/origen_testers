require 'origen/generator'
module Origen
  class Generator
    # Makes more sense for this plugin to own this method now
    def generate_program(file, options)
      Origen.file_handler.resolve_files(file, ignore_with_prefix: '_', default_dir: "#{Origen.root}/program") do |path|
        Origen.file_handler.current_file = path
        j = Job.new(path, options)
        j.pattern = path
        j.run
      end
      Origen.interface.write_files(options)
      unless options[:quiet] || !Origen.interface.write?
        if options[:referenced_pattern_list]
          file = "#{Origen.root}/list/#{options[:referenced_pattern_list]}"
        else
          file = Origen.config.referenced_pattern_list
        end
        puts "Referenced pattern list written to: #{Pathname.new(file).relative_path_from(Pathname.pwd)}"
        dir = Pathname.new(file).dirname
        FileUtils.mkdir_p(dir) unless dir.exist?
        File.open(file, 'w') do |f|
          Origen.interface.referenced_patterns.uniq.sort.each do |pat|
            f.puts pat
          end
        end
      end
    end
  end
end
