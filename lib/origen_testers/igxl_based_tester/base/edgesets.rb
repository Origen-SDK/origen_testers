module OrigenTesters
  module IGXLBasedTester
    class Base
      class Edgesets
        include ::OrigenTesters::Generator

        attr_accessor :es
        attr_accessor :es_sheet_pins
        attr_accessor :ts_basic

        OUTPUT_PREFIX = 'ES'
        # OUTPUT_POSTFIX = 'ES'

        def initialize(options = {}) # :nodoc:
          @es       = {}
          @ts_basic = options[:timeset_basic]
        end

        def add(esname, pin, edge, options = {})
          esname = esname.to_sym unless esname.is_a? Symbol
          pin = pin.to_sym unless pin.is_a? Symbol
          @es.key?(esname) ? @es[esname].add_edge(pin, edge) : @es[esname] = platform::Edgeset.new(esname, pin, edge, options)
          @es_sheet_pins = options[:es_sheet_pins] unless @es_sheet_pins
          @es
        end

        def finalize(options = {})
        end

        # Populate an array of pins based on the pin or pingroup
        def get_pin_objects(grp)
          pins = []
          if Origen.top_level.pin(grp).is_a?(Origen::Pins::Pin) ||
             Origen.top_level.pin(grp).is_a?(Origen::Pins::FunctionProxy)
            pins << Origen.top_level.pin(grp)
          elsif Origen.top_level.pin(grp).is_a?(Origen::Pins::PinCollection)
            Origen.top_level.pin(grp).each do |pin|
              pins << pin
            end
          else
            Origen.log.error "Could not find pin class: #{grp}  #{Origen.top_level.pin(grp).class}"
          end
          pins
        end

        # Equality check to compare full contents of edge object
        def edges_eql?(edge1, edge2)
          edge1 == edge2
        end

        # Globally modify text within the edge object
        def gsub_edges!(edge, old_val, new_val)
          edge.d_src   = edge.d_src.gsub(/#{Regexp.escape(old_val)}/, new_val)
          edge.d_fmt   = edge.d_fmt.gsub(/#{Regexp.escape(old_val)}/, new_val)
          edge.d0_edge = edge.d0_edge.gsub(/#{Regexp.escape(old_val)}/, new_val)
          edge.d1_edge = edge.d1_edge.gsub(/#{Regexp.escape(old_val)}/, new_val)
          edge.d2_edge = edge.d2_edge.gsub(/#{Regexp.escape(old_val)}/, new_val)
          edge.d3_edge = edge.d3_edge.gsub(/#{Regexp.escape(old_val)}/, new_val)
          edge.c_mode  = edge.c_mode.gsub(/#{Regexp.escape(old_val)}/, new_val)
          edge.c1_edge = edge.c1_edge.gsub(/#{Regexp.escape(old_val)}/, new_val)
          edge.c2_edge = edge.c2_edge.gsub(/#{Regexp.escape(old_val)}/, new_val)
          edge.t_res   = edge.t_res.gsub(/#{Regexp.escape(old_val)}/, new_val)
          edge.clk_per = edge.clk_per.gsub(/#{Regexp.escape(old_val)}/, new_val)
        end

        # Prepare the edge information for ES/TS file output
        def format_uflex_edge(data, line_cnt, options = {})
          options = {
            no_disable: false
          }.merge(options)

          if data !~ /^\s*$/
            data = data.gsub(/^/, '=')
          end
          data = data.gsub(/(\W)([a-zA-Z])/, '\1_\2')

          case data
          when /_d0_edge|_d_on/
            data = data.gsub(/_d0_edge|_d_on/, "F#{line_cnt}")
          when /_d1_edge|_d_data/
            data = data.gsub(/_d1_edge|_d_data/, "G#{line_cnt}")
          when /_d2_edge|_dret/
            data = data.gsub(/_d2_edge|_dret/, "H#{line_cnt}")
          when /_d3_edge|_d_off/
            data = data.gsub(/_d3_edge|_d_off/, "I#{line_cnt}")
          when /_c1_edge|_c_open/
            data = data.gsub(/_c1_edge|_c_open/, "K#{line_cnt}")
          when /_c2_edge|_c_close/
            data = data.gsub(/_c2_edge|_c_close/, "L#{line_cnt}")
          when /^\s*$/
            options[:no_disable] ? data = '' : data = 'disable'
          else
            data
          end
        end

        # Prepare the edge information for TSB file output
        def format_uflex_edge_tsb(data, line_cnt, options = {})
          options = {
            no_disable: false
          }.merge(options)

          if data !~ /^\s*$/
            data = data.gsub(/^/, '=')
          end
          data = data.gsub(/(\W)([a-zA-Z])/, '\1_\2')

          case data
          when /_d0_edge|_d_on/
            data = data.gsub(/_d0_edge|_d_on/, "I#{line_cnt}")
          when /_d1_edge|_d_data/
            data = data.gsub(/_d1_edge|_d_data/, "J#{line_cnt}")
          when /_d2_edge|_dret/
            data = data.gsub(/_d2_edge|_dret/, "K#{line_cnt}")
          when /_d3_edge|_d_off/
            data = data.gsub(/_d3_edge|_d_off/, "L#{line_cnt}")
          when /_c1_edge|_c_open/
            data = data.gsub(/_c1_edge|_c_open/, "N#{line_cnt}")
          when /_c2_edge|_c_close/
            data = data.gsub(/_c2_edge|_c_close/, "O#{line_cnt}")
          when /^\s*$/
            options[:no_disable] ? data = '' : data = 'disable'
          else
            data
          end
        end
      end
    end
  end
end
