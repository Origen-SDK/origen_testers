module OrigenTesters
  module SmartestBasedTester
    class V93K
      class Builder
        # Responsible for modelling/building the contents of a V93K flow file
        class Flow
          attr_reader :information, :declarations, :flags, :testmethodparameters,
                      :testmethodlimits, :testmethods, :test_suites, :test_flow, :binning,
                      :hardware_bin_descriptions, :file

          def initialize(file = nil)
            @information = {}
            @declarations = {}
            @flags = {}
            @testmethodparameters = {}
            @testmethodlimits = {}
            @testmethods = {}
            @test_suites = {}
            @test_flow = []
            @binning = []
            @hardware_bin_descriptions = {}
            @groups = {}
            @file = file
            parse_file if file
          end

          def add_sub_flow(flow)
            combine(flow, :information, exclude: 'test_revision')
            combine(flow, :declarations)
            combine(flow, :flags)
            add_test_methods(flow)
            add_test_suites(flow)
            add_flow(flow)
            (binning << flow.binning).flatten!.uniq!
            combine(flow, :hardware_bin_descriptions)
          end

          private

          def parse_file
            current_section = nil
            current = nil
            File.open(file) do |f|
              f.each_line do |line|
                if current_section
                  if line =~ /^\s*end\s*$/
                    current_section = nil
                    current = nil
                  else
                    case current_section
                    when :information, :declarations, :flags, :hardware_bin_descriptions
                      if line =~ /^\s*(.*)\s*=\s*(.*)\s*$/
                        send(current_section)[Regexp.last_match(1).strip] = Regexp.last_match(2).strip
                      end
                    when :testmethodparameters, :testmethodlimits, :testmethods, :test_suites
                      if line =~ /^\s*(.*):\s*$/
                        current = Regexp.last_match(1)
                        send(current_section)[current] = {}
                      elsif current
                        if line =~ /^\s*(.*)\s*=\s*(.*)\s*$/
                          send(current_section)[current][Regexp.last_match(1).strip] = Regexp.last_match(2).strip
                        end
                      end
                    when :binning
                      binning << line.strip
                    when :test_flow
                      add_flow_line(line)
                    end
                  end
                else
                  if line =~ /^\s*(information|declarations|flags|testmethodparameters|testmethodlimits|testmethods|test_suites|test_flow|binning|hardware_bin_descriptions)\s*$/
                    current_section = Regexp.last_match(1).to_sym
                    current = nil
                  end
                end
              end
            end
          end

          def groups
            @groups
          end

          def add_flow(flow)
            flow.test_flow.each { |l| add_flow_line(l) }
          end

          def add_flow_line(line)
            line.strip!
            # Make group names unique as required
            if line =~ /\s*},\s*open\s*,\s*("|')(.*)("|'),.*/
              group = Regexp.last_match(2).strip
              if groups[group]
                line = line.sub(group, "#{group} #{groups[group]}")
                groups[group] += 1
              else
                groups[group] = 1
              end
            end
            test_flow << line
          end

          def combine(flow, attribute, options = {})
            exclude = [options[:exclude]].flatten.compact
            flow.send(attribute).each do |key, val|
              unless exclude.include?(key)
                if send(attribute)[key]
                  if send(attribute)[key] != val
                    puts "#{flow} assigns #{attribute} attribute #{key} to #{val}, however it is already assigned to #{send(attribute)[key]}"
                    exit 1
                  end
                else
                  send(attribute)[key] = val
                end
              end
            end
          end

          # Add the test methods from the given flow to this flow
          def add_test_methods(flow)
            flow.testmethods.each do |id, tm|
              # If this flow already contains a test method with the current ID
              if testmethods[id]
                nid = "tm_#{tm_ix}"
                testmethods[nid] = tm
                testmethodparameters[nid] = flow.testmethodparameters[id]
                testmethodlimits[nid] = flow.testmethodlimits[id]
                flow.test_suites.each do |tsid, ts|
                  if ts['override_testf'] == "#{id};" && !ts[:new_id]
                    ts['override_testf'] = "#{nid};"
                    ts[:new_id] = true
                  end
                end
              else
                testmethods[id] = tm
                testmethodparameters[id] = flow.testmethodparameters[id]
                testmethodlimits[id] = flow.testmethodlimits[id]
              end
            end
            # Remove this temporary flag to prevent it rendering to the output file
            flow.test_suites.each do |tsid, ts|
              ts.delete(:new_id)
            end
          end

          def add_test_suites(flow)
            flow.test_suites.each do |id, ts|
              # If this flow already contains a test suite with the current ID
              if test_suites[id]
                i = 1
                nid = id
                while test_suites[nid]
                  nid = "#{id}_#{i}"
                  i += 1
                end
                test_suites[nid] = ts
                flow.test_flow.map! do |line|
                  if line =~ /(run|run_and_branch)\(#{id}\)/ && line !~ /--NEW_ID--/
                    line = line.sub(id, nid)
                    line += '--NEW_ID--'
                  else
                    line
                  end
                end
              else
                test_suites[id] = ts
              end
            end
            flow.test_flow.map! do |line|
              line.sub('--NEW_ID--', '')
            end
          end

          def tm_ix
            testmethods.size + 1
          end
        end
      end
    end
  end
end
