module OrigenTesters
  module IGXLBasedTester
    # Currently, we aren't differentiating between J750 and UFLEX testers. They'll both use the same until
    # there are difference that require forking the decompiler.

    def self.suitable_decompiler_for(pattern: nil, tester: nil, **options)
      if pattern && (Pathname(pattern).extname == ".#{OrigenTesters::IGXLBasedTester.pat_extension}")
        OrigenTesters::IGXLBasedTester::Pattern
      elsif tester && (tester == 'j750' || tester == 'uflex' || tester == 'ultraflex')
        OrigenTesters::IGXLBasedTester::Pattern
      end
    end
    extend OrigenTesters::Decompiler::API
    register_decompiler(self)

    class Pattern < OrigenTesters::Decompiler::Pattern
      require_relative './decompiler/atp'
      extend Atp

      @platform = 'j750'
      @splitter_config = {
        pinlist_start:              /^vector/,
        vectors_start:              /^{/,
        vectors_end:                /^}/,
        vectors_include_start_line: false,
        vectors_include_end_line:   false
      }

      @platform_tokens = {
        comment_start: OrigenTesters::IGXLBasedTester.comment_char
      }
    end

    def self._sample_direct_source_
      [
        '// Sample pattern text for the J750',
        '// Source located at: lib/origen_testers/igxl_based_tester/decompiler',
        '',
        'import tset tp0;',
        'svm_only_file = no;',
        'opcode_mode = extended;',
        'compressed = yes;',
        '',
        'vector ($tset, tclk, tdi, tdo, tms)',
        '{',
        'start_label pattern_st:',
        '// Start of vector body',
        'repeat 2 > tp0 X X X X ; // First Vector',
        'repeat 5 > tp0 1 0 X 1 ;',
        'end_module   > tp0 X X X X ; // Last Vector',
        '}'
      ]
    end

    def self.sample_direct_source
      _sample_direct_source_.join("\n")
    end

    def self.write_sample_source
      unless Dir.exist?(sample_source_atp.dirname)
        Origen.log.info "Creating directory #{sample_source_atp.dirname}"
        FileUtils.mkdir_p(sample_source_atp.dirname)
      end
      File.open(sample_source_atp, 'w').puts(sample_direct_source)
      sample_source_atp
    end

    def self.sample_source_atp
      Origen.app!.root.join('approved/j750/decompiler/sample/sample.atp')
    end
  end
end
