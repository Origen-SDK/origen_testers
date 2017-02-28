class OrigenTestersApplication < Origen::Application
  # See http://origen.freescale.net/origen/latest/api/Origen/Application/Configuration.html
  # for a full list of the configuration options available

  config.shared = {
    :command_launcher => "config/shared_commands.rb"
  }

  # This information is used in headers and email templates, set it specific
  # to your application
  config.name     = 'Origen Testers'
  config.initials = 'OrigenTesters'
  self.name = 'origen_testers'
  self.namespace = 'OrigenTesters'
  config.rc_url   = "git@github.com:Origen-SDK/origen_testers.git"
  config.release_externally = true

  # Added list of directory to exclude when run running origen rc unman
  config.unmanaged_dirs = %w[spec/patterns/bin]

  config.unmanaged_files = %w[]

  config.web_directory = "git@github.com:Origen-SDK/Origen-SDK.github.io.git/testers"
  config.web_domain = "http://origen-sdk.org/testers"

  # When false Origen will be less strict about checking for some common coding errors,
  # it is recommended that you leave this to true for better feedback and easier debug.
  # This will be the default setting in Origen v3.
  config.strict_errors = true

  config.semantically_version = true

  # to handle for web compile where environment/tester not yet defined
  tester_name = $tester.nil? ? '' : $tester.name

  # By default all generated output will end up in ./output.
  # Here you can specify an alternative directory entirely, or make it dynamic such that
  # the output ends up in a setup specific directory.
  config.output_directory do
    dir =  "#{Origen.root}/output/#{tester_name}"
  # Check if running on windows, if so, substitute :: with _ 
   dir.gsub!("::","_") if Origen.os.windows?
   dir
  end

  # Similary for the reference files, generally you want to setup the reference directory
  # structure to mirror that of your output directory structure.
  config.reference_directory do
    dir = "#{Origen.root}/.ref/#{tester_name}"
  # Check if running on windows, if so, substitute :: with _
    dir.gsub!("::","_") if Origen.os.windows?
    dir
  end
  
  # Setting this to the spec area for testing of compiler
  config.pattern_output_directory do
   dir = "#{Origen.root}/spec/patterns/atp"
  # Check if running on windows, if so, substitute :: with _
   dir.gsub!("::","_") if Origen.os.windows?
   dir
  end

  # Run the tests before deploying to generate test coverage numbers
  def before_deploy_site
    Dir.chdir Origen.root do
      system 'origen examples -c'
      system 'origen specs -c'
      dir = "#{Origen.root}/web/output/coverage"
      FileUtils.remove_dir(dir, true) if File.exist?(dir)
      system "mv #{Origen.root}/coverage #{dir}"
    end
  end

  # This will automatically deploy your documentation after every tag
  def after_release_email(tag, note, type, selector, options)
    command = "origen web compile --remote --api --comment 'Release of #{Origen.app.name} #{Origen.app.version}'"
    Dir.chdir Origen.root do
      system command
    end
  end

  # Ensure that all tests pass before allowing a release to continue
   def validate_release
    if !system("origen examples") # || !system("origen specs")
      puts "Sorry but you can't release with failing tests, please fix them and try again."
      exit 1
    else
      puts "All tests passing, proceeding with release process!"
    end
   end

  # Help to find patterns based on an iterator
  config.pattern_name_translator do |name|
    if name == 'dummy_name'
      { :source => 'timing', :output => 'timing' }
    else
      name.gsub(/_b\d/, '_bx')
    end
  end

  if current?  # Standalone only configs

    # By block iterator
    config.pattern_iterator do |iterator|
      iterator.key = :by_block
  
      iterator.loop do |&pattern|
        $nvm.blocks.each do |block|
          pattern.call(block)
        end
      end
  
      iterator.setup do |block|
        blk = $nvm.find_block_by_id(block.id)
        blk.select
        blk
      end
  
      iterator.pattern_name do |name, block|
        name.gsub('_bx', "_b#{block.id}")
      end
    end
  
    # By setting iterator
    config.pattern_iterator do |iterator|
      iterator.key = :by_setting
  
      iterator.loop do |settings, &pattern|
        settings.each do |setting|
          pattern.call(setting)
        end
      end
  
      iterator.pattern_name do |name, setting|
        name.gsub('_x', "_#{setting}")
      end
    end
  
  end # standalone only configs

  # Set up lint test
  config.lint_test = {
    # Require the lint tests to pass before allowing a release to proceed
    :run_on_tag => true,
    # Auto correct violations where possible whenever 'origen lint' is run
    :auto_correct => true,
    # Limit the testing for large legacy applications
    #:level => :easy,
    # Run on these directories/files by default
    #:files => ["lib", "config/application.rb"],
  }
end
