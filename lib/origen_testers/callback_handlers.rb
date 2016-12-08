module OrigenTesters
  class CallbackHandlers
    include Origen::PersistentCallbacks

    # Snoop the pattern path that was just created and then compile it
    # if the compiler was passed on the command line
    def pattern_generated(path_to_generated_pattern)
      current_compiler = select_compiler
      run_compiler(current_compiler, path_to_generated_pattern)
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

    private

    def select_compiler
      current_compiler = nil
      if $compiler == :use_app_default
        current_compiler = $dut.compiler
        fail "DUT compiler '#{current_compiler}' is not instantiated" if $dut.pattern_compilers[current_compiler].nil?
      elsif $compiler.is_a? Symbol
        current_compiler = $compiler
        fail "Command line compiler '#{current_compiler}' is not instantiated" if $dut.pattern_compilers[current_compiler].nil?
      end
      current_compiler
    end

    def run_compiler(current_compiler, pattern)
      unless current_compiler.nil?
        debug "Compiling pattern #{pattern} with compiler '#{current_compiler}'..."
        $dut.pattern_compilers[current_compiler].find_jobs(pattern)
        $dut.pattern_compilers[current_compiler].run
      end
    end
  end

  # Instantiate an instance of this class immediately when this file is required, this object will
  # then listen for the remainder of the Origen thread
  CallbackHandlers.new
end
