module OrigenTesters
  module IGXLBasedTester
    class Base
      class Edge
        attr_accessor :d_src, :d_fmt, :d0_edge, :d1_edge, :d2_edge, :d3_edge  # Input pin timing information
        attr_accessor :c_mode, :c1_edge, :c2_edge                             # Output pin timing information
        attr_accessor :t_res, :clk_per

        def initialize(options = {}) # :nodoc:
          options = {
            d_src:   'PAT',     # source of the channel drive data (e.g. pattern, drive_hi, drive_lo, etc.)
            d_fmt:   'NR',      # drive data format (NR, RL, RH, etc.)
            d0_edge: '',        # time at which the input drive is turned on
            d1_edge: '',        # time of the initial data drive edge
            d2_edge: '',        # time of the return format data drive edge
            d3_edge: '',        # time at which the input drive is turned off
            c_mode:  'Edge',    # output compare mode
            c1_edge: '',        # time of the initial output compare edge
            c2_edge: '',        # time of the final output compare edge (window compare)
            t_res:   'Machine', # timing resolution (possibly ATE-specific)
            clk_per: ''         # clock period equation - for use with MCG
          }.merge(options)
          @d_src    = options[:d_src]
          @d_fmt    = options[:d_fmt]
          @d0_edge  = options[:d0_edge]
          @d1_edge  = options[:d1_edge]
          @d2_edge  = options[:d2_edge]
          @d3_edge  = options[:d3_edge]
          @c_mode   = options[:c_mode]
          @c1_edge  = options[:c1_edge]
          @c2_edge  = options[:c2_edge]
          @t_res    = options[:t_res]
          @clk_per  = options[:clk_per]
        end

        def ==(edge)
          if edge.is_a? Edge
            d_src == edge.d_src &&
            d_fmt == edge.d_fmt &&
            d0_edge == edge.d0_edge &&
            d1_edge == edge.d1_edge &&
            d2_edge == edge.d2_edge &&
            d3_edge == edge.d3_edge &&
            c_mode == edge.c_mode &&
            c1_edge == edge.c1_edge &&
            c2_edge == edge.c2_edge &&
            t_res == edge.t_res &&
            clk_per == edge.clk_per
          else
            super
          end
        end

        def platform
          Origen.interface.platform
        end
      end
    end
  end
end
