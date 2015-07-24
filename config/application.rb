require 'pry'
class Testers_Application < RGen::Application
  # See http://rgen.freescale.net/rgen/latest/api/RGen/Application/Configuration.html
  # for a full list of the configuration options available

  config.shared = {
    :command_launcher => "config/shared_commands.rb"
  }

  # This information is used in headers and email templates, set it specific
  # to your application
  config.name     = 'Testers'
  config.initials = 'Testers'
  config.vault    = 'sync://sync-15088:15088/Projects/common_tester_blocks/rgen_blocks/tester/Testers/tool_data/rgen'

  # Gem name
  self.name = 'rgen_testers'
  self.namespace = 'Testers'

  # Added list of directory to exclude when run running rgen rc unman
  config.unmanaged_dirs = %w[spec/patterns/bin]

  config.unmanaged_files = %w[]

  # To enable deployment of your documentation to a web server (via the 'rgen web'
  # command) fill in these attributes. The example here is configured to deploy to
  # the rgen.freescale.net domain, which is an easy option if you don't have another
  # server already in mind. To do this you will need an account on CDE and to be a member
  # of the 'rgen' group.
  config.web_directory = '/proj/.web_rgen/html/testers'
  config.web_domain = 'http://rgen.freescale.net/testers'

  # When false RGen will be less strict about checking for some common coding errors,
  # it is recommended that you leave this to true for better feedback and easier debug.
  # This will be the default setting in RGen v3.
  config.strict_errors = true

  config.semantically_version = true

  # By default all generated output will end up in ./output.
  # Here you can specify an alternative directory entirely, or make it dynamic such that
  # the output ends up in a setup specific directory.
  config.output_directory do
    "#{RGen.root}/output/#{$tester.name}"
  end

  # Similary for the reference files, generally you want to setup the reference directory
  # structure to mirror that of your output directory structure.
  config.reference_directory do
    "#{RGen.root}/.ref/#{$tester.name}"
  end
  
  # Setting this to the spec area for testing of compiler
  config.pattern_output_directory do
    "#{RGen.root}/spec/patterns/atp"
  end

  # Run the tests before deploying to generate test coverage numbers
  def before_deploy_site
    Dir.chdir RGen.root do
      system 'rgen examples -c'
      system 'rgen specs -c'
      dir = "#{RGen.root}/web/output/coverage"
      FileUtils.remove_dir(dir, true) if File.exist?(dir)
      system "mv #{RGen.root}/coverage #{dir}"
    end
  end

  # This will automatically deploy your documentation after every tag
  def after_release_email(tag, note, type, selector, options)
    deployer = RGen.app.deployer
    if deployer.running_on_cde? && deployer.user_belongs_to_rgen?
      command = 'rgen web compile --remote --api'
      if RGen.app.version.production?
        command += " --archive #{RGen.app.version}"
      end
      Dir.chdir RGen.root do
        system command
      end
    end
  end

  # Ensure that all tests pass before allowing a release to continue
   def validate_release
    if !system("rgen examples") # || !system("rgen specs")
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
    # Auto correct violations where possible whenever 'rgen lint' is run
    :auto_correct => true,
    # Limit the testing for large legacy applications
    #:level => :easy,
    # Run on these directories/files by default
    #:files => ["lib", "config/application.rb"],
  }
end
