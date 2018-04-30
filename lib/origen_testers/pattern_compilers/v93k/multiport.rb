module OrigenTesters
  module PatternCompilers
    class V93KPatternCompiler
      module MultiportAPI
        class Multiport
          attr_accessor :port_in_focus, :port_bursts, :prefix, :postfix

          def initialize(options)
            @port_in_focus = nil

            if options && options[:port_in_focus]
              @port_in_focus = options[:port_in_focus]
              @port_bursts = options[:port_bursts]
              @prefix = options[:prefix].nil? ? '' : "#{options[:prefix]}_"
              @postfix = options[:postfix].nil? ? '' : "_#{options[:postfix]}"
            end
          end

          def render_aiv_lines(pattern)
            mpb_entry = []
            mpb_entry << ''
            mpb_entry << render_mpb_header(pattern)
            mpb_entry << render_mpb_port_line(pattern)
            mpb_entry << render_mpb_burst_line(pattern)
            mpb_entry
          end

          def enabled?
            port_in_focus.nil? ? false : true
          end

          private

          def render_mpb_header(pattern)
            "MULTI_PORT_BURST #{prefix}#{pattern}#{postfix}"
          end

          def render_mpb_port_line(pattern)
            line = 'PORTS '
            line += port_in_focus.to_s
            line += mpb_padding(port_in_focus.to_s, pattern, 0)
            if port_bursts
              port_bursts.each do |k, v|
                line += k.to_s
                line += mpb_padding(k.to_s, v.to_s, 0)
              end
            end
            line
          end

          def render_mpb_burst_line(pattern)
            line = '      '
            line += pattern.to_s
            line += mpb_padding(port_in_focus.to_s, pattern, 1)
            if port_bursts
              port_bursts.each do |k, v|
                line += v.to_s
                line += mpb_padding(k.to_s, v.to_s, 1)
              end
            end
            line
          end

          def mpb_padding(str0, str1, index = 0)
            width = str0.size > str1.size ? str0.size : str1.size
            index == 0 ? ' ' * (width + 2 - str0.size) : ' ' * (width + 2 - str1.size)
          end
        end

        def multiport
          @multiport ||= Multiport.new(@user_options[:multiport])
        end

        def multiport?
          multiport.enabled?
        end
      end
    end
  end
end
