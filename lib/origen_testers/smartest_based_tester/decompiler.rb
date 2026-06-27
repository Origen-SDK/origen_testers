module OrigenTesters
  module SmartestBasedTester
    def self.suitable_decompiler_for(pattern: nil, tester: nil, **options)
      if pattern && (Pathname(pattern).extname == '.avc')
        OrigenTesters::SmartestBasedTester::Pattern
      elsif tester && tester == 'v93k'
        OrigenTesters::SmartestBasedTester::Pattern
      end
    end
    extend OrigenTesters::Decompiler::API
    register_decompiler(self)

    class Pattern < OrigenTesters::Decompiler::Pattern
      require_relative './decompiler/avc'
      extend Avc

      @platform = 'v93k'
      @splitter_config = {
        pinlist_start: /^FORMAT/,

        # The vectors start will be picked up right after the pinlist is parsed.
        # We'll throw away any whitespace we encounter between the pinlist and
        #   first vector element though.
        vectors_start: proc do |line:, index:, current_indices:|
          # The pinlist was encountered. Start the vectors at the next line
          # that's not just whitespace
          if current_indices[:pinlist_start] && line !~ /^\s/
            next true
          end

          false
        end,

        # V93K doesn't have any endmatter, or vector end delimiter, so just
        # grab vectors until the end of the file is reached.
        vectors_end:   -1
      }

      @platform_tokens = {
        comment_start: '#'
      }
    end
  end
end
