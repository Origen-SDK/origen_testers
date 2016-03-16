module OrigenTesters
  module IGXLBasedTester
    class Base
      class Edgesets
        include ::OrigenTesters::Generator

        attr_accessor :es

        OUTPUT_PREFIX = 'ES_'
        OUTPUT_POSTFIX = ''

        def initialize # :nodoc:
          @es = {}
        end

        def add(esname, pin, edge, options = {})
          esname = esname.to_sym unless esname.is_a? Symbol
          pin = pin.to_sym unless pin.is_a? Symbol
          @es.key?(esname) ? @es[esname].add_edge(pin, edge) : @es[esname] = platform::Edgeset.new(esname, pin, edge, options)
          @es
        end

        def finalize(options = {})
        end

        # Equality check to compare full contents of edge object
        def edges_eql?(edge1, edge2)
          edge1.d_src == edge2.d_src && edge1.d_fmt == edge2.d_fmt &&
            edge1.d0_edge == edge2.d0_edge && edge1.d1_edge == edge2.d1_edge &&
            edge1.d2_edge == edge2.d2_edge && edge1.d3_edge == edge2.d3_edge &&
            edge1.c_mode == edge2.c_mode &&
            edge1.c1_edge == edge2.c1_edge && edge1.c2_edge == edge2.c2_edge &&
            edge1.t_res == edge2.t_res && edge1.clk_per == edge2.clk_per
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
      end
    end
  end
end
