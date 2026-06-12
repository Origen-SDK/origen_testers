require 'json'

module OrigenTesters
  # Round-trip provenance sidecar (tester-agnostic plumbing).
  #
  # Every tester renderer walks the same ATP AST, and every AST node already carries
  # provenance: a unique id, source file/line, the full flow-file lineage
  # (source_stack), and any domain provenance a plugin attached via options[:meta]
  # (the rt_* keys). This module collects that provenance as each output element is
  # rendered and writes it to a `<output_file>.sourcemap.json` sidecar.
  #
  # It is deliberately platform-neutral: it does NOT know what an SMT8 "suite", an
  # SMT7 test-instance, or an IGXL flow-row is. The renderer is responsible for the
  # one platform-specific thing -- the join KEY (the element's name as it appears in
  # that platform's output file) -- which it passes to record_sourcemap_entry. The
  # collection, meta extraction, append-merge, and file writing are all shared here.
  #
  # To enable for a tester:
  #   include OrigenTesters::Sourcemap
  #   - call record_sourcemap_entry(node, key, kind) from each on_* render hook
  #   - reset_sourcemap before the AST walk (e.g. in finalize)
  #   - call write_sourcemap_file after the output file is written (e.g. write_to_file)
  #
  # Purely additive: it only reads strings already on the AST nodes and writes an
  # extra file. It never changes the generated program output.
  module Sourcemap
    # Append a provenance record for a single rendered output element.
    #
    # @param node [OrigenTesters::ATP::AST::Node] the AST node being rendered
    # @param key [String] the element's name as it appears in the platform output
    #   file (the join key the reverse pass uses to match a diff back to source)
    # @param kind [String] element kind, e.g. 'test', 'sub_flow', 'auxiliary_flow'
    # @param test_method [Object, nil] the TML-aware test method, captured at RENDER
    #   time (the end-state right before the output is written, after all finalize and
    #   any user modification). Its parameter keys are the authoritative native tester
    #   parameter names + final rendered values for the loaded client/TML version.
    # Gate: the sourcemap is OFF by default and only emitted when a site enables it via
    # site_config (AMD turns it on internally; upstream/non-AMD users see no change and
    # pay no cost). Returns false unless Origen.site_config.roundtrip_sourcemap is truthy.
    def roundtrip_sourcemap_enabled?
      return @roundtrip_sourcemap_enabled unless @roundtrip_sourcemap_enabled.nil?
      @roundtrip_sourcemap_enabled = begin
        # ENV override lets a controlled in-process regeneration (e.g. the `origen
        # roundtrip` command regenerating the original to diff against) force the
        # sidecar on for that run, without depending on the site_config default.
        if %w(1 true).include?(ENV['ROUNDTRIP_SOURCEMAP'].to_s.downcase)
          true
        else
          v = Origen.site_config.respond_to?(:roundtrip_sourcemap) ? Origen.site_config.roundtrip_sourcemap : nil
          [true, 'true', 1, '1'].include?(v)
        end
      rescue StandardError
        false
      end
    end

    def record_sourcemap_entry(node, key, kind, test_method = nil)
      # When disabled, do no work at all -- skip the (potentially expensive) TML
      # format() collection entirely so there is zero render-time overhead.
      return unless roundtrip_sourcemap_enabled?
      @sourcemap ||= []
      entry = {
        # 'suite' retained as the key field name for backward compatibility with the
        # reverse tool; it holds whatever join key the platform supplied.
        'suite'        => key.to_s,
        'kind'         => kind,
        'node_id'      => (node.respond_to?(:id) ? node.id : nil),
        'source_file'  => (node.respond_to?(:file) ? node.file : nil),
        'source_line'  => (node.respond_to?(:line_number) ? node.line_number : nil),
        'source_stack' => (node.respond_to?(:source_stack) ? node.source_stack : nil)
      }
      prov = extract_meta_provenance(node)
      tml = extract_tml_params(test_method)
      entry['provenance'] = prov unless prov.empty?
      entry['tml_params'] = tml unless tml.empty?
      @sourcemap << entry
    end

    # Capture the FINAL native tester parameter names + values for this test, at render
    # time (the true end-state, after build + finalize + any user changes, immediately
    # before the param is written to the output file).
    #
    # The actual extraction is AMD/TML-specific knowledge (what a TML param is, how to
    # read its rendered value), so it is OWNED by amd_test_helpers and delegated to here
    # via the interface: if the loaded interface defines roundtrip_capture_tml_params,
    # we call it. This keeps origen_testers generic (no TML coupling) while still firing
    # at the correct render-time moment, which is the only point the live finalized
    # test_method is guaranteed reachable (SMT8 sub-flows render in forked processes, so
    # a later program-level callback cannot see these objects).
    def extract_tml_params(test_method)
      return {} unless test_method
      iface = (defined?(Origen) && Origen.respond_to?(:interface_loaded?) && Origen.interface_loaded?) ? Origen.interface : nil
      return {} unless iface && iface.respond_to?(:roundtrip_capture_tml_params)
      result = iface.roundtrip_capture_tml_params(test_method)
      result.is_a?(Hash) ? result : {}
    rescue StandardError
      {}
    end

    # Pull the rt_* (and any other) attributes out of the node's (meta ...) child.
    # Structure is: (meta (attribute "rt_burst" "value") (attribute "rt_mode" "x") ...)
    def extract_meta_provenance(node)
      result = {}
      return result unless node.respond_to?(:find)
      meta = node.find(:meta)
      return result unless meta
      meta.to_a.each do |attr|
        next unless attr.respond_to?(:type) && attr.type == :attribute
        k, v = *attr.to_a
        result[k.to_s] = v.to_s unless k.nil?
      end
      result
    end

    def sourcemap_entries
      @sourcemap ||= []
    end

    # Reset the accumulator. Call before each AST walk (finalize may run >once) so
    # re-rendering does not duplicate entries.
    def reset_sourcemap
      @sourcemap = []
    end

    # Where the sidecar is written: a hidden '.roundtrip/' subdirectory NEXT TO the
    # generated output file, named '<output-basename>.sourcemap.json'.
    #
    # The sourcemap is a DERIVED build artifact (regenerated from source every run) and
    # is large, so it must NOT be checked into revision control. Placing it under a
    # dedicated hidden dir keeps it out of the tester-facing output and makes it a single
    # trivially-gitignorable entry ('output/**/.roundtrip/'). The reverse tool reads it
    # from there for the run that produced the program; it is never committed.
    def sourcemap_output_file
      out = output_file
      base = out.basename(out.extname).to_s
      dir = out.dirname.join('.roundtrip')
      FileUtils.mkdir_p(dir.to_s) unless dir.exist?
      Pathname.new(dir.join("#{base}.sourcemap.json"))
    end

    def write_sourcemap_file
      return if sourcemap_entries.empty?
      return unless Origen.interface.respond_to?(:write?) ? Origen.interface.write? : true
      entries = sourcemap_entries
      # When several flow objects append to the same output file, each writes its own
      # portion; merge with whatever is already on disk so the sidecar stays in sync
      # with the appended output content.
      if @append && sourcemap_output_file.exist?
        begin
          existing = JSON.parse(File.read(sourcemap_output_file))
          entries = (existing['entries'] || []) + entries
        rescue StandardError
          # If the existing sidecar is unreadable, fall back to current entries only
        end
      end
      doc = {
        'version'      => 1,
        'flow'         => output_file.basename.to_s,
        'flow_path'    => output_file.to_s,
        'generated_by' => 'origen_testers roundtrip provenance',
        'entries'      => entries
      }
      File.open(sourcemap_output_file, 'w') { |f| f.puts JSON.pretty_generate(doc) }
      Origen.log.info "Writing... #{sourcemap_output_file.basename}"
    end
  end
end
