module OrigenTesters
  module PatternCompilers
    class V93KPatternCompiler
      module DigCapAPI
        class DigCap
          attr_accessor :owner, :pins, :vps, :nrf, :char

          def initialize(owner, options)
            @owner = owner
            @pins = nil

            if options && options[:skip_setup]
              @skip_setup = options[:skip_setup]   # optional: force skip of AVI digcap setup
              #                                                e.g. handled by RDI
            elsif options && options[:pins] && options[:vps]
              @pins = options[:pins]           # required: pins to be captured
              @vps = options[:vps]             # required: vecotrs per sample
              @nrf = options[:nrf] || 1        # optional: nr_frames (defaults to 1)
              @char = options[:char] || 'C'    # optional: vector character representing capture
            elsif options
              fail 'Must specifiy pins and vps for digcap setup!'
            end
          end

          def render_aiv_lines
            lines = []
            unless @skip_setup
              lines << ''
              lines << 'AI_DIGCAP_SETTINGS {'
              lines << render_digcap_header
              avc_files.each do |f|
                if vec_per_frame[f.to_sym] > 0
                  lines << render_digcap_entry(f)
                end
              end
              lines << '};'
            end
            lines
          end

          def capture_string
            " #{char * num_pins} "
          end

          def num_pins
            if pins.is_a? String
              pins.split(' ').size
            elsif pins.is_a? Symbol
              dut.pins(pins).size
            elsif pins.is_a? Array
              fail 'Digcap Pins does not support array yet'
            end
          end

          def enabled?
            pins.nil? ? false : true
          end

          def empty?
            vec_per_frame.each do |k, v|
              return false if v > 0
            end
            true       # digcap setup but no avc contain capture vectors
          end

          private

          def render_digcap_header
            line = 'variable'.ljust(max_filename_size + 4)
            line += '  '
            line += 'label'.ljust(max_filename_size)
            line += '  '
            line += 'vec_per_frame  vec_per_sample  nr_frames  {pins};'
            line
          end

          def render_digcap_entry(pattern)
            line = "#{pattern}_var".ljust(max_filename_size + 4)
            line += '  '
            line += "#{pattern}".ljust(max_filename_size)
            line += '  '
            line += "#{vec_per_frame[pattern.to_sym]}".ljust(15)
            line += "#{vps}".ljust(16)
            line += "#{nrf}".ljust(11)
            line += "{#{pins}};"
            line
          end

          def avc_files
            owner.avc_files
          end

          def max_filename_size
            owner.max_avcfilename_size
          end

          def vec_per_frame
            owner.vec_per_frame
          end
        end

        def digcap
          @digcap ||= DigCap.new(self, @user_options[:digcap])
        end

        def digcap?
          digcap.enabled?
        end
      end
    end
  end
end
