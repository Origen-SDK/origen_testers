module OrigenTesters
  class CallbackHandlers
    include Origen::PersistentCallbacks

    # Snoop the pattern path that was just created and then compile it
    # if the compiler was passed on the command line
    def pattern_generated(path_to_generated_pattern, job_options = {})
      if job_options[:testers_compile_pat]
        opts = {}
        opts[:compiler_instance] = job_options[:testers_compiler_instance_name]
        opts[:pattern_generated] = true
        OrigenTesters::PatternCompilers::Runner.run_compiler(path_to_generated_pattern, opts)
      end
    end

    # Listen for a pattern with .atp or .atp.gz extension.  If found then compile the fileand kill the 'origen g' command
    def before_pattern_lookup(requested_pattern)
      path = Pathname.new(requested_pattern)
      patname = path.basename
      dir = path.dirname
      if patname.to_s.match(/.atp/)
        if patname.extname == '.atp' || patname.extname == '.gz'
          # Found a .atp or .atp.gz file so we should compile it
          matches = Dir.glob("#{Origen.root}/**/#{patname}")
          fail "Found multiple locations for #{patname}, exiting...\n\t#{matches}" if matches.size > 1

          pattern = matches.first.to_s
          current_compiler = select_compiler
          run_compiler(current_compiler, pattern)
          $compile = true
        end
        # Return false so the Origen generate command stops
        return false
      end
      true
    end
  end

  # Instantiate an instance of this class immediately when this file is required, this object will
  # then listen for the remainder of the Origen thread
  CallbackHandlers.new
end
