module OrigenTesters
  module PatternCompilers
    module Runner
      # Run the pattern (or list) through the (specified) compiler
      def self.run_compiler(pattern, options = {})
        compiler = nil
        if options[:compiler_instance]
          compiler = options[:compiler_instance]
          unless dut.pattern_compilers.include? compiler
            fail_msg = "Pattern Compiler instance '#{compiler}' does not exist for this tester, "
            fail_msg += "choose from \(#{dut.pattern_compilers.keys.join(', ')}\) or change tester target."
            fail fail_msg
          end
        else
          if dut.pattern_compilers.count == 1
            # Only one compiler defined (for current platform), use that one
            compiler = dut.pattern_compilers.keys[0]
          else
            # Multiple compilers defined, used one assigned to default or named :default, otherwise fail
            if dut.default_pattern_compiler
              compiler = dut.default_pattern_compiler
            elsif dut.pattern_compilers.keys.include? :default
              compiler = :default
            else
              fail_msg = "No 'default' Pattern Compiler defined, choose from "
              fail_msg += "\(#{dut.pattern_compilers.keys.join(', ')}\) or set one to be the default."
              fail fail_msg
            end
          end
        end

        Origen.log.info "Compiling...  #{pattern}"

        # Everything is verified and ready, last thing to do is COMPILE
        dut.pattern_compilers[compiler].find_jobs(pattern)
        dut.pattern_compilers[compiler].run
      end
    end
  end
end
