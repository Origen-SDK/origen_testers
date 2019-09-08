module OrigenTesters
  module Test
    class ComplexTimingDUT
      include Origen::TopLevel

      def initialize(options = {})
        add_timeset(:complex_timing)
        timeset(:complex_timing) do |t|
          t.period_in_ns = 1
          t.drive_wave(:tclk) do |w|
            w.drive(0, at: 0)
            w.drive(:data, at: 'period/2')
          end
        end
      end

      def startup
        tester.set_timeset(:complex_timing)
      end
    end
  end
end
