module OrigenTesters
  module IGXLBasedTester
    class UltraFLEX < Base
      class ATEHardware
        attr_accessor :instrument

        def initialize(instrumentname)
          @name = 'ultraflex'
          @instrument ||= instrumentname
        end

        def ppmu
          ppmu = Struct.new(:forcei, :forcev, :measi, :measv, :vclamp)

          if @instrument == 'HSD-M' # also known as HSD1000
            forcei = [20.uA, 200.uA, 2.mA, 50.mA]
            forcev = { forcei_50mA__gt_20mA:       (-0.1.V..4.5.V),
                       forcei_50mA__lte_20mA:      (-1.V..6.V),
                       forcei_Non50mA__half_scale: (-1..6.V),
                       forcei_Non50mA__full_scale: (-1.V..5.5.V) }
            measi = [2.uA, 20.uA, 200.uA, 2.mA, 50.mA]
            measv =  { measi_50mA__gt_20mA:         (-0.1.V..4.5.V),
                       measi_50mA__lte_20mA:        (-1.V..6.V),
                       measi_20mA__0p5mA_to_20mA:   (-1.V..5.5.V),
                       measi_20mA__0p05mA_to_1mA:   (-1.V..6.V),
                       measi_20mA__n0p5mA_to_0p5mA: (-1.85.V..6.V),
                       measi_20mA__n1mA_to_n0p5mA:  (-1.V..6.V),
                       measi_20mA__n2mA_to_n1mA:    (-1.V..5.5.V),
                       measi_200uA__half_scale:     (-1.V..6.V),
                       measi_200uA__full_scale:     (-1.V..5.V),
                       measi_20uA__half_scale:      (-1.V..6.V),
                       measi_20uA__full_scale:      (-1.V..5.5.V) }
            vclamp = (-2.V..6.5.V)
            ppmu.new(forcei, forcev, measi, measv, vclamp)
          elsif @instrument == 'HSD-U'  # also known as Ultrapin1600 or Utah
            forcei = [20.uA, 200.uA, 2.mA, 50.mA]
            forcev = { forcei_50mA__20mA_to_50mA:   (-0.1.V..4.5.V),
                       forcei_50mA__0mA_to_20mA:    (-1.V..6.V),
                       forcei_50mA__n20mA_to_0mA:   (-0.1.V..6.V),
                       forcei_50mA__n35mA_to_n20mA: (0.5.V..5.1.V),
                       forcei_50mA__n50mA_to_n35mA: (1.1.V..4.5.V),
                       forcei_Non50mA:              (-1.V..6.V) }
            measi = [2.uA, 20.uA, 200.uA, 2.mA, 50.mA]
            measv = { measi_50mA:              (-1.V..6.V),
                      measi_200uA:             (-1.V..6.V),
                      measi_20uA:              (-1.V..6.V),
                      measi_2mA__1mA_to_2mA:   (-1.V..6.V),
                      measi_2mA__n1mA_to_1mA:  (-1.5.V..6.V),
                      measi_2mA__n2mA_to_n1mA: (-1.V..6.V) }
            vclamp = (-1.5.V..6.5.V)
            ppmu.new(forcei, forcev, measi, measv, vclamp)
          elsif @instrument == 'HSD-4G'
            forcei = [200.uA, 2.mA, 30.mA]
            forcev = { measi_30mA:  [min: '1.5V, 1.5V - 50mV/mA * Idut', max: '0V, -50mV/mA * Idut'],
                       measi_2mA:   (-1.V..1.5.V),
                       measi_200uA: (-1.V..1.5.V) }
            measi = [200.uA, 2.mA, 30.mA]
            measv = (-1.V..1.5.V)
            vclamp = 'n/a'
            ppmu.new(forcei, forcev, measi, measv, vclamp)
          elsif @instrument == 'HSS-6G' # also known as SB6G
            forcei = [200.uA, 2.mA,  50.mA]
            forcev = { forcei_50mA__gt_20mA:  (-0.1.V..3.6.V),
                       forcei_50mA__lte_20mA: (-1.V..3.6.V),
                       forcei_2mA:            (-1.V..3.6.V),
                       forcei_200uA:          (-1.V..3.6.V) }
            measi = [200.uA, 2.mA, 50.mA]
            measv = { measi_50mA__gt_20mA:  (-0.1.V..3.6.V),
                      measi_50mA__lte_20mA: (-1.V..3.6.V),
                      measi_200uA:          (-1.V..3.6.V),
                      measi_2mA:            (-1.V..3.6.V) }
            vclamp = (-1.3.V..3.9.V)
            ppmu.new(forcei, forcev, measi, measv, vclamp)
          else
            puts 'please enter an instrument type: e.g. $tester.ate_hardware("HSD-M").ppmu'
            puts 'Instrument type available: "HSD-M", "HSD-U", "HSD-4G", and "HSS-6G" '
            puts 'HSD-U is also known as Ultrapin1600.  HSS-6G is also known as SB6G.'
          end
        end

        def supply
          supply = Struct.new(:forcev, :irange, :source_overload_i, :source_overload_t, :source_fold_i,
                              :source_fold_t, :sink_overload_i, :sink_overload_t, :sink_fold_i,
                              :sink_fold_t, :meter_irange, :meter_vrange, :tdelay, :accuracy,
                              :filter, :bandwidth)
          if @instrument == 'VSM'
            forcev = (0.V..4.V)
            irange = [1.A, 11.A, 21.A, 51.A, 81.A]
            source_overload_i = { irange_1A:  (100.mA..1.08.A),
                                  irange_11A: (1.1.A..11.88.A),
                                  irange_21A: (2.1.A..22.68.A),
                                  irange_51A: (5.1.A..55.08.A),
                                  irange_81A: (8.1.A..87.48.A) }
            source_overload_t = (10.uS..8.S)
            source_fold_i = { irange_1A:  (50.mA..1.03.A),
                              irange_11A: (550.mA..11.33.A),
                              irange_21A: (1.05.A..21.63.A),
                              irange_51A: (2.55.A..52.53.A),
                              irange_81A: (4.05.A..83.43.A) }
            source_fold_t = (10.uS..8.S)
            sink_overload_i = { irange_1A:  [max: 78.mA],    # ?????    Not programmable?
                                irange_11A: [max: 858.mA],    # ?????    Not programmable?
                                irange_21A: [max: 1.64.A],    # ?????    Not programmable?
                                irange_51A: [max: 3.98.A],    # ?????    Not programmable?
                                irange_81A: [max: 6.32.A] }    # ?????    Not programmable?
            sink_overload_t = 0                  # ?????    Not programmable?
            sink_fold_i = { irange_1A:  [max: 78.mA],      # ?????    Not programmable?
                            irange_11A: [max: 858.mA],     # ?????    Not programmable?
                            irange_21A: [max: 1.64.A],     # ?????    Not programmable?
                            irange_51A: [max: 3.98.A],    # ?????    Not programmable?
                            irange_81A: [max: 6.32.A] }    # ?????    Not programmable?
            sink_fold_t = (10.uS..8.S)
            meter_irange = { irange_1A:  [1.25.A, 2.5.A],
                             irange_11A: [13.75.A, 27.5.A],
                             irange_21A: [26.25.A, 52.5.A],
                             irange_51A: [63.75.A, 127.5.A],
                             irange_81A: [101.25.A, 202.5.A] }
            meter_vrange = [3.V, 6.V]
            tdelay = 0                     # default tdelay
            accuracy = { neg: -2.mV, pos: 2.mV }
            filter = [635, 2539, 40_625]
            bandwidth = [0, 1, 2, 3, 4]
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'VSMx2'  # Also known as VSM, Merged2
            forcev = (0.V..4.V)
            irange = [1.A, 2.A, 11.A, 21.A, 51.A, 81.A, 102.A, 162.A]
            source_overload_i = { irange_1A:   (100.mA..1.08.A),
                                  irange_2A:   (200.mA..2.16.A),
                                  irange_11A:  (1.1.A..11.88.A),
                                  irange_21A:  (2.1.A..22.68.A),
                                  irange_51A:  (5.1.A..55.08.A),
                                  irange_81A:  (8.1.A..87.48.A),
                                  irange_102A: (10.2.A..110.16.A),
                                  irange_162A: (16.2.A..174.96.A) }
            source_overload_t = (10.uS..8.S)
            source_fold_i = { irange_1A:   (50.mA..1.03.A),
                              irange_2A:   (100.mA..2.06.A),
                              irange_11A:  (550.mA..11.33.A),
                              irange_21A:  (1.05.A..21.63.A),
                              irange_51A:  (2.55.A..52.53.A),
                              irange_81A:  (4.05.A..83.43.A),
                              irange_102A: (5.1.A..105.06.A),
                              irange_162A: (8.1.A..166.86.A) }
            source_fold_t = (10.uS..8.S)
            sink_overload_i = { irange_1A:   [max: 78.mA],     # ?????    Not programmable?
                                irange_2A:   [max: 156.mA],     # ?????    Not programmable?
                                irange_11A:  [max: 858.mA],     # ?????    Not programmable?
                                irange_21A:  [max: 1.64.A],     # ?????    Not programmable?
                                irange_51A:  [max: 3.98.A],     # ?????    Not programmable?
                                irange_81A:  [max: 6.32.A],     # ?????    Not programmable?
                                irange_102A: [max: 7.96.A],     # ?????    Not programmable?
                                irange_162A: [max: 12.64.A] }     # ?????    Not programmable?
            sink_overload_t = 0                  # ?????    Not programmable?
            sink_fold_i = { irange_1A:   [max: 78.mA],     # ?????    Not programmable?
                            irange_2A:   [max: 156.mA],     # ?????    Not programmable?
                            irange_11A:  [max: 858.mA],     # ?????    Not programmable?
                            irange_21A:  [max: 1.64.A],     # ?????    Not programmable?
                            irange_51A:  [max: 3.98.A],     # ?????    Not programmable?
                            irange_81A:  [max: 6.32.A],     # ?????    Not programmable?
                            irange_102A: [max: 7.96.A],     # ?????    Not programmable?
                            irange_162A: [max: 12.64.A] }     # ?????    Not programmable?
            meter_irange = { irange_1A:   [1.25.A, 2.5.A],
                             irange_2A:   [2.5.A, 5.A],
                             irange_11A:  [13.75.A, 27.5.A],
                             irange_21A:  [26.25.A, 52.5.A],
                             irange_51A:  [63.75.A, 127.5.A],
                             irange_81A:  [101.25.A, 202.5.A],
                             irange_102A: [127.5.A, 255.A],
                             irange_162A: [202.5.A, 405.A] }
            sink_fold_t = (10.uS..8.S)
            meter_vrange = [3.V, 6.V]
            tdelay = 0                     # default tdelay
            accuracy = { neg: -2.mV, pos: 2.mV }
            filter = [635, 2539, 40_625]
            bandwidth = [0, 1, 2, 3, 4]
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'HexVS'
            forcev = (0.V..5.5.V)
            irange = 15.A
            source_overload_i = (1.05.A..16.5.A)
            source_overload_t = (102.4.uS..300.mS)
            source_fold_i = (50.mA..15.5.A)
            source_fold_t = (102.4.uS..5.S)
            sink_overload_i = (2.A..3.A)
            sink_overload_t = (102.4.uS..300.mS)
            sink_fold_i = (1.A..2.A)
            sink_fold_t = (102.4.uS..5.S)
            meter_irange = [10.mA, 100.mA, 1.A, 15.A]
            meter_vrange = [4.V, 8.V]
            tdelay = 0                     # default tdelay
            accuracy = { neg: -7.mV, pos: 7.mV }
            filter = 10_000
            bandwidth = [0, 1, 2, 3, 4, 5, 6, 7]
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'HexVSx2'  # Also known as HexVS, Merged2
            forcev = (0.V..5.5.V)
            irange = [15.A, 30.A]
            source_overload_i = { irange_15A: (1.05.A..16.5.A),
                                  irange_30A: (2.1.A..33.A) }
            source_overload_t = (102.4.uS..300.mS)
            source_fold_i = { irange_15A: (50.mA..15.5.A),
                              irange_30A: (100.mA..31.A) }
            source_fold_t = (102.4.uS..5.S)
            sink_overload_i = { irange_15A: (2.A..3.A),
                                irange_30A: (4.A..6.A) }
            sink_overload_t = (102.4.uS..300.mS)
            sink_fold_i = { irange_15A: (1.A..2.A),
                            irange_30A: (2.A..4.A) }
            sink_fold_t = (102.4.uS..5.S)
            meter_irange = { irange_15A: [10.mA, 100.mA, 1.A, 15.A],
                             irange_30A: [30.A] } # This is verified to be correct on tester.
            meter_vrange = [4.V, 8.V]
            tdelay = 0                     # default tdelay
            accuracy = { neg: -7.mV, pos: 7.mV }
            filter = 10_000
            bandwidth = [0, 1, 2, 3, 4, 5, 6, 7]
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'HexVSx4'  # Also known as HexVS, Merged4
            forcev = (0.V..5.5.V)
            irange = [15.A, 60.A]
            source_overload_i = { irange_15A: (1.05.A..16.5.A),
                                  irange_60A: (4.2.A..66.A) }
            source_overload_t = (102.4.uS..300.mS)
            source_fold_i = { irange_15A: (50.mA..15.5.A),
                              irange_60A: (200.mA..62.A) }
            source_fold_t = (102.4.uS..5.S)
            sink_overload_i = { irange_15A: (2.A..3.A),
                                irange_60A: (8.A..12.A) }
            sink_overload_t = (102.4.uS..300.mS)
            sink_fold_i = { irange_15A: (1.A..2.A),
                            irange_60A: (4.A..8.A) }
            sink_fold_t = (102.4.uS..5.S)
            meter_irange = { irange_15A: [10.mA, 100.mA, 1.A, 15.A],
                             irange_60A: [60.A] } # This is verified to be correct on tester.
            meter_vrange = [4.V, 8.V]
            tdelay = 0                     # default tdelay
            accuracy = { neg: -7.mV, pos: 7.mV }
            filter = 10_000
            bandwidth = [0, 1, 2, 3, 4, 5, 6, 7]
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'HexVSx6'  # Also known as HexVS, Merged6
            forcev = (0.V..5.5.V)
            irange = [15.A, 90.A]
            source_overload_i = { irange_15A: (1.05.A..16.5.A),
                                  irange_90A: (6.3.A..99.A) }
            source_overload_t = (102.4.uS..300.mS)
            source_fold_i = { irange_15A: (50.mA..15.5.A),
                              irange_90A: (300.mA..93.A) }
            source_fold_t = (102.4.uS..5.S)
            sink_overload_i = { irange_15A: (2.A..3.A),
                                irange_90A: (12.A..18.A) }
            sink_overload_t = (102.4.uS..300.mS)
            sink_fold_i = { irange_15A: (1.A..2.A),
                            irange_90A: (6.A..12.A) }
            sink_fold_t = (102.4.uS..5.S)
            meter_irange = { irange_15A: [10.mA, 100.mA, 1.A, 15.A],
                             irange_90A: [90.A] } # This is verified to be correct on tester.
            meter_vrange = [4.V, 8.V]
            tdelay = 0                     # default tdelay
            accuracy = { neg: -7.mV, pos: 7.mV }
            filter = 10_000
            bandwidth = [0, 1, 2, 3, 4, 5, 6, 7]
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'HexVS+'
            forcev = (0.V..5.5.V)
            irange = 15.A
            source_overload_i = (1.05.A..16.5.A)
            source_overload_t = (102.4.uS..300.mS)
            source_fold_i = (50.mA..15.5.A)
            source_fold_t = (102.4.uS..5.S)
            sink_overload_i = (2.A..3.A)
            sink_overload_t = (102.4.uS..300.mS)
            sink_fold_i = (1.A..2.A)
            sink_fold_t = (102.4.uS..5.S)
            meter_irange = [10.mA, 100.mA, 1.A, 15.A]
            meter_vrange = [4.V, 8.V]
            tdelay = 0                     # default tdelay
            accuracy = { neg: -2.mV, pos: 2.mV }
            filter = 10_000
            bandwidth = [0, 1, 2, 3, 4, 5, 6, 7]
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'HexVS+x2'  # Also known as HexVS+, Merged2
            forcev = (0.V..5.5.V)
            irange = [15.A, 30.A]
            source_overload_i = { irange_15A: (1.05.A..16.5.A),
                                  irange_30A: (2.1.A..33.A) }
            source_overload_t = (102.4.uS..300.mS)
            source_fold_i = { irange_15A: (50.mA..15.5.A),
                              irange_30A: (100.mA..31.A) }
            source_fold_t = (102.4.uS..5.S)
            sink_overload_i = { irange_15A: (2.A..3.A),
                                irange_30A: (4.A..6.A) }
            sink_overload_t = (102.4.uS..300.mS)
            sink_fold_i = { irange_15A: (1.A..2.A),
                            irange_30A: (2.A..4.A) }
            sink_fold_t = (102.4.uS..5.S)
            meter_irange = { irange_15A: [10.mA, 100.mA, 1.A, 15.A],
                             irange_30A: [30.A] } # This is verified to be correct on tester.
            meter_vrange = [4.V, 8.V]
            tdelay = 0                     # default tdelay
            accuracy = { neg: -2.mV, pos: 2.mV }
            filter = 10_000
            bandwidth = [0, 1, 2, 3, 4, 5, 6, 7]
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'HexVS+x4'  # Also known as HexVS+, Merged4
            forcev = (0.V..5.5.V)
            irange = [15.A, 60.A]
            source_overload_i = { irange_15A: (1.05.A..16.5.A),
                                  irange_60A: (4.2.A..66.A) }
            source_overload_t = (102.4.uS..300.mS)
            source_fold_i = { irange_15A: (50.mA..15.5.A),
                              irange_60A: (200.mA..62.A) }
            source_fold_t = (102.4.uS..5.S)
            sink_overload_i = { irange_15A: (2.A..3.A),
                                irange_60A: (8.A..12.A) }
            sink_overload_t = (102.4.uS..300.mS)
            sink_fold_i = { irange_15A: (1.A..2.A),
                            irange_60A: (4.A..8.A) }
            sink_fold_t = (102.4.uS..5.S)
            meter_irange = { irange_15A: [10.mA, 100.mA, 1.A, 15.A],
                             irange_60A: [60.A] } # This is verified to be correct on tester.
            meter_vrange = [4.V, 8.V]
            tdelay = 0                     # default tdelay
            accuracy = { neg: -2.mV, pos: 2.mV }
            filter = 10_000
            bandwidth = [0, 1, 2, 3, 4, 5, 6, 7]
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'HexVS+x6'  # Also known as HexVS+, Merged6
            forcev = (0.V..5.5.V)
            irange = [15.A, 90.A]
            source_overload_i = { irange_15A: (1.05.A..16.5.A),
                                  irange_90A: (6.3.A..99.A) }
            source_overload_t = (102.4.uS..300.mS)
            source_fold_i = { irange_15A: (50.mA..15.5.A),
                              irange_90A: (300.mA..93.A) }
            source_fold_t = (102.4.uS..5.S)
            sink_overload_i = { irange_15A: (2.A..3.A),
                                irange_90A: (12.A..18.A) }
            sink_overload_t = (102.4.uS..300.mS)
            sink_fold_i = { irange_15A: (1.A..2.A),
                            irange_90A: (6.A..12.A) }
            sink_fold_t = (102.4.uS..5.S)
            meter_irange = { irange_15A: [10.mA, 100.mA, 1.A, 15.A],
                             irange_90A: [90.A] } # This is verified to be correct on tester.
            meter_vrange = [4.V, 8.V]
            tdelay = 0                     # default tdelay
            accuracy = { neg: -2.mV, pos: 2.mV }
            filter = 10_000
            bandwidth = [0, 1, 2, 3, 4, 5, 6, 7]
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'HDVS1'  # also known as HDVS
            forcev = (0.V..7.V)
            irange = 1.A
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = (5.mA..1.A)
            source_fold_t = (0.S..167.77.mS)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = (5.mA..200.mA)
            sink_fold_t = (0.S..167.77.mS)
            meter_irange = [10.uA, 100.uA, 1.mA, 10.mA, 100.mA, 1.A]
            meter_vrange = 7.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-10.mV', pos: '0.001xSUPPLY+10.mV' }
            filter = [1356, 2712, 5425, 10_850, 21_701, 43_402, 86_805, 173_611, 347_222,
                      694_444, 1_388_888, 2_777_777, 5_555_555]
            bandwidth = [0, 1, 2, 3, 4, 10, 11, 12, 13, 14, 20, 21, 22, 23, 24,
                         100, 101, 102, 103, 104, 220, 221, 222, 223, 224, 470,
                         471, 472, 473, 474]
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'HDVS1x2'  # also known as HDVS, Merged2
            forcev = (0.V..7.V)
            irange = 2.A
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = (10.mA..2.A)
            source_fold_t = (0.S..167.77.mS)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = (10.mA..400.mA)
            sink_fold_t = (0.S..167.77.mS)
            meter_irange = [20.uA, 200.uA, 2.mA, 20.mA, 200.mA, 2.A]
            meter_vrange = 7.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-10.mV', pos: '0.001xSUPPLY+10.mV' }
            filter = [1356, 2712, 5425, 10_850, 21_701, 43_402, 86_805, 173_611, 347_222,
                      694_444, 1_388_888, 2_777_777, 5_555_555]
            bandwidth = [0, 1, 2, 3, 4, 10, 11, 12, 13, 14, 20, 21, 22, 23, 24,
                         100, 101, 102, 103, 104, 220, 221, 222, 223, 224, 470,
                         471, 472, 473, 474]
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'HDVS1x4'  # also known as HDVS, Merged4
            forcev = (0.V..7.V)
            irange = [4.A]
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = (20.mA..4.A)
            source_fold_t = (0.S..167.77.mS)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = (20.mA..800.mA)
            sink_fold_t = (0.S..167.77.mS)
            meter_irange = [40.uA, 400.uA, 4.mA, 40.mA, 400.mA, 4.A]
            meter_vrange = 7.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-10.mV', pos: '0.001xSUPPLY+10.mV' }
            filter = [1356, 2712, 5425, 10_850, 21_701, 43_402, 86_805, 173_611, 347_222,
                      694_444, 1_388_888, 2_777_777, 5_555_555]
            bandwidth = [0, 1, 2, 3, 4, 10, 11, 12, 13, 14, 20, 21, 22, 23, 24,
                         100, 101, 102, 103, 104, 220, 221, 222, 223, 224, 470,
                         471, 472, 473, 474]
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'VHDVS'  # also known as UVS256
            forcev = (-2.V..18.V)
            irange = [4.uA, 20.uA, 200.uA, 2.mA, 20.mA, 200.mA]
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = { irange_4uA:   (500.nA..4.uA),
                              irange_20uA:  (2.5.uA..20.uA),
                              irange_200uA: (25.uA..200.uA),
                              irange_2mA:   (250.uA..2.mA),
                              irange_20mA:  (2.5.mA..20.mA),
                              irange_200mA: (25.mA..200.mA) }
            source_fold_t = (300.uS..2.S)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = { irange_4uA:   (500.nA..4.uA),
                            irange_20uA:  (2.5.uA..20.uA),
                            irange_200uA: (25.uA..200.uA),
                            irange_2mA:   (250.uA..2.mA),
                            irange_20mA:  (2.5.mA..20.mA),
                            irange_200mA: (25.mA..75.mA) }
            sink_fold_t = (300.uS..2.S)
            meter_irange = { irange_4uA:   4.uA,
                             irange_20uA:  20.uA,
                             irange_200uA: 200.uA,
                             irange_2mA:   2.mA,
                             irange_20mA:  20.mA,
                             irange_200mA: 200.mA }
            meter_vrange = 18.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-10.mV', pos: '0.001xSUPPLY+10.mV' }
            filter = [49, 98, 195, 391, 781, 1563, 3125, 6250, 12_500, 25_000, 50_000, 100_000, 200_000]
            bandwidth = (0..255)   # Integers
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'VHDVS_HC'  # also known as UVS256, High-Current
            forcev = (-2.V..18.V)
            irange = [4.uA, 20.uA, 200.uA, 2.mA, 20.mA, 200.mA, 700.mA, 800.mA]
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = { irange_4uA:   (500.nA..4.uA),
                              irange_20uA:  (2.5.uA..20.uA),
                              irange_200uA: (25.uA..200.uA),
                              irange_2mA:   (250.uA..2.mA),
                              irange_20mA:  (2.5.mA..20.mA),
                              irange_200mA: (25.mA..200.mA),
                              irange_700mA: (100.mA..700.mA),
                              irange_800mA: (100.mA..800.mA) }
            source_fold_t = (300.uS..2.S)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = { irange_4uA:   (500.nA..4.uA),
                            irange_20uA:  (2.5.uA..20.uA),
                            irange_200uA: (25.uA..200.uA),
                            irange_2mA:   (250.uA..2.mA),
                            irange_20mA:  (2.5.mA..20.mA),
                            irange_200mA: (25.mA..75.mA),
                            irange_700mA: (90.mA..110.mA), # This is verified on tester
                            irange_800mA: (90.mA..110.mA) } # This is verified on tester
            sink_fold_t = (300.uS..2.S)
            meter_irange = { irange_4uA:   4.uA,
                             irange_20uA:  20.uA,
                             irange_200uA: 200.uA,
                             irange_2mA:   2.mA,
                             irange_20mA:  20.mA,
                             irange_200mA: 200.mA,
                             irange_700mA: 700.mA,
                             irange_800mA: 800.mA }
            meter_vrange = 18.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-10.mV', pos: '0.001xSUPPLY+10.mV' }
            filter = [49, 98, 195, 391, 781, 1563, 3125, 6250, 12_500, 25_000, 50_000, 100_000, 200_000]
            bandwidth = (0..255)   # Integers
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'VHDVSx2'  # also known as UVS256, Merged2
            forcev = (-2.V..18.V)
            irange = [4.uA, 20.uA, 200.uA, 2.mA, 20.mA, 40.mA, 200.mA, 400.mA]
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = { irange_4uA:   (500.nA..4.uA),
                              irange_20uA:  (2.5.uA..20.uA),
                              irange_200uA: (25.uA..200.uA),
                              irange_2mA:   (250.uA..2.mA),
                              irange_20mA:  (2.5.mA..20.mA),
                              irange_40mA:  (5.mA..40.mA),
                              irange_200mA: (25.mA..200.mA),
                              irange_400mA: (50.mA..400.mA) }
            source_fold_t = (300.uS..2.S)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = { irange_4uA:   (500.nA..4.uA),
                            irange_20uA:  (2.5.uA..20.uA),
                            irange_200uA: (25.uA..200.uA),
                            irange_2mA:   (250.uA..2.mA),
                            irange_20mA:  (2.5.mA..20.mA),
                            irange_40mA:  (5.mA..40.mA),
                            irange_200mA: (25.mA..75.mA),
                            irange_400mA: (50.mA..150.mA) }
            sink_fold_t = (300.uS..2.S)
            meter_irange = { irange_4uA:   4.uA,
                             irange_20uA:  20.uA,
                             irange_200uA: 200.uA,
                             irange_2mA:   2.mA,
                             irange_20mA:  20.mA,
                             irange_40mA:  40.mA,
                             irange_200mA: 200.mA,
                             irange_400mA: 400.mA }
            meter_vrange = 18.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-10.mV', pos: '0.001xSUPPLY+10.mV' }
            filter = [49, 98, 195, 391, 781, 1563, 3125, 6250, 12_500, 25_000, 50_000, 100_000, 200_000]
            bandwidth = (0..255)   # Integers
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'VHDVS_HCx2'  # also known as UVS256, High-Current, Merged2
            forcev = (-2.V..18.V)
            irange = [4.uA, 20.uA, 200.uA, 2.mA, 20.mA, 40.mA, 200.mA, 400.mA, 700.mA, 1.4.A]
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = { irange_4uA:   (500.nA..4.uA),
                              irange_20uA:  (2.5.uA..20.uA),
                              irange_200uA: (25.uA..200.uA),
                              irange_2mA:   (250.uA..2.mA),
                              irange_20mA:  (2.5.mA..20.mA),
                              irange_40mA:  (5.mA..40.mA),
                              irange_200mA: (25.mA..200.mA),
                              irange_400mA: (50.mA..400.mA),
                              irange_700mA: (100.mA..700.mA),
                              irange_1p4A:  (200.mA..1.4.A) }
            source_fold_t = (300.uS..2.S)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = { irange_4uA:   (500.nA..4.uA),
                            irange_20uA:  (2.5.uA..20.uA),
                            irange_200uA: (25.uA..200.uA),
                            irange_2mA:   (250.uA..2.mA),
                            irange_20mA:  (2.5.mA..20.mA),
                            irange_40mA:  (5.mA..40.mA),
                            irange_200mA: (25.mA..75.mA),
                            irange_400mA: (50.mA..150.mA),
                            irange_700mA: (90.mA..110.mA), # This is verified on tester
                            irange_1p4A:  (190.mA..210.mA) } # This is verified on tester
            sink_fold_t = (300.uS..2.S)
            meter_irange = { irange_4uA:   4.uA,
                             irange_20uA:  20.uA,
                             irange_200uA: 200.uA,
                             irange_2mA:   2.mA,
                             irange_20mA:  20.mA,
                             irange_40mA:  40.mA,
                             irange_200mA: 200.mA,
                             irange_400mA: 400.mA,
                             irange_700mA: 700.mA,
                             irange_1p4A:  1.4.A }
            meter_vrange = 18.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-10.mV', pos: '0.001xSUPPLY+10.mV' }
            filter = [49, 98, 195, 391, 781, 1563, 3125, 6250, 12_500, 25_000, 50_000, 100_000, 200_000]
            bandwidth = (0..255)   # Integers
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'VHDVS_HCx4'  # also known as UVS256, High-Current, Merged4
            forcev = (-2.V..18.V)
            irange = [4.uA, 20.uA, 200.uA, 2.mA, 20.mA, 200.mA, 700.mA, 2.8.A]
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = { irange_4uA:   (500.nA..4.uA),
                              irange_20uA:  (2.5.uA..20.uA),
                              irange_200uA: (25.uA..200.uA),
                              irange_2mA:   (250.uA..2.mA),
                              irange_20mA:  (2.5.mA..20.mA),
                              irange_200mA: (25.mA..200.mA),
                              irange_700mA: (100.mA..700.mA),
                              irange_2p8A:  (400.mA..2.8.A) }
            source_fold_t = (300.uS..2.S)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = { irange_4uA:   (500.nA..4.uA),
                            irange_20uA:  (2.5.uA..20.uA),
                            irange_200uA: (25.uA..200.uA),
                            irange_2mA:   (250.uA..2.mA),
                            irange_20mA:  (2.5.mA..20.mA),
                            irange_200mA: (25.mA..75.mA),
                            irange_700mA: (90.mA..110.mA), # This is verified on tester
                            irange_2p8A:  (390.mA..410.mA) } # This is verified on tester
            sink_fold_t = (300.uS..2.S)
            meter_irange = { irange_4uA:   4.uA,
                             irange_20uA:  20.uA,
                             irange_200uA: 200.uA,
                             irange_2mA:   2.mA,
                             irange_20mA:  20.mA,
                             irange_200mA: 200.mA,
                             irange_700mA: 700.mA,
                             irange_2p8A:  2.8.A }
            meter_vrange = 18.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-10.mV', pos: '0.001xSUPPLY+10.mV' }
            filter = [49, 98, 195, 391, 781, 1563, 3125, 6250, 12_500, 25_000, 50_000, 100_000, 200_000]
            bandwidth = (0..255)   # Integers
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'VHDVS_HCx8'  # also known as UVS256, High-Current, Merged8
            forcev = (-2.V..18.V)
            irange = [4.uA, 20.uA, 200.uA, 2.mA, 20.mA, 200.mA, 700.mA, 5.6.A]
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = { irange_4uA:   (500.nA..4.uA),
                              irange_20uA:  (2.5.uA..20.uA),
                              irange_200uA: (25.uA..200.uA),
                              irange_2mA:   (250.uA..2.mA),
                              irange_20mA:  (2.5.mA..20.mA),
                              irange_200mA: (25.mA..200.mA),
                              irange_700mA: (100.mA..700.mA),
                              irange_5p6A:  (800.mA..5.6.A) }
            source_fold_t = (300.uS..2.S)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = { irange_4uA:   (500.nA..4.uA),
                            irange_20uA:  (2.5.uA..20.uA),
                            irange_200uA: (25.uA..200.uA),
                            irange_2mA:   (250.uA..2.mA),
                            irange_20mA:  (2.5.mA..20.mA),
                            irange_200mA: (25.mA..75.mA),
                            irange_700mA: (90.mA..110.mA), # This is verified on tester
                            irange_5p6A:  (790.mA..810.mA) } # This is verified on tester
            sink_fold_t = (300.uS..2.S)
            meter_irange = { irange_4uA:   4.uA,
                             irange_20uA:  20.uA,
                             irange_200uA: 200.uA,
                             irange_2mA:   2.mA,
                             irange_20mA:  20.mA,
                             irange_200mA: 200.mA,
                             irange_700mA: 700.mA,
                             irange_5p6A:  5.6.A }
            meter_vrange = 18.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-10.mV', pos: '0.001xSUPPLY+10.mV' }
            filter = [49, 98, 195, 391, 781, 1563, 3125, 6250, 12_500, 25_000, 50_000, 100_000, 200_000]
            bandwidth = (0..255)   # Integers
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'VHDVS+'  # also known as UVS256, High-Accuracy
            forcev = (-2.V..18.V)
            irange = [4.uA, 20.uA, 200.uA, 2.mA, 20.mA, 200.mA]
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = { irange_4uA:   (500.nA..4.uA),
                              irange_20uA:  (2.5.uA..20.uA),
                              irange_200uA: (25.uA..200.uA),
                              irange_2mA:   (250.uA..2.mA),
                              irange_20mA:  (2.5.mA..20.mA),
                              irange_200mA: (25.mA..200.mA) }
            source_fold_t = (300.uS..2.S)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = { irange_4uA:   (500.nA..4.uA),
                            irange_20uA:  (2.5.uA..20.uA),
                            irange_200uA: (25.uA..200.uA),
                            irange_2mA:   (250.uA..2.mA),
                            irange_20mA:  (2.5.mA..20.mA),
                            irange_200mA: (25.mA..75.mA) }
            sink_fold_t = (300.uS..2.S)
            meter_irange = { irange_4uA:   4.uA,
                             irange_20uA:  20.uA,
                             irange_200uA: 200.uA,
                             irange_2mA:   2.mA,
                             irange_20mA:  20.mA,
                             irange_200mA: 200.mA }
            meter_vrange = 18.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-5.mV', pos: '0.001xSUPPLY+5.mV' }
            filter = [49, 98, 195, 391, 781, 1563, 3125, 6250, 12_500, 25_000, 50_000, 100_000, 200_000]
            bandwidth = (0..255)   # Integers
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'VHDVS_HC+'  # also known as UVS256, High-Current, High-Accuracy
            forcev = (-2.V..18.V)
            irange = [4.uA, 20.uA, 200.uA, 2.mA, 20.mA, 200.mA, 700.mA, 800.mA]
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = { irange_4uA:   (500.nA..4.uA),
                              irange_20uA:  (2.5.uA..20.uA),
                              irange_200uA: (25.uA..200.uA),
                              irange_2mA:   (250.uA..2.mA),
                              irange_20mA:  (2.5.mA..20.mA),
                              irange_200mA: (25.mA..200.mA),
                              irange_700mA: (100.mA..700.mA),
                              irange_800mA: (100.mA..800.mA) }
            source_fold_t = (300.uS..2.S)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = { irange_4uA:   (500.nA..4.uA),
                            irange_20uA:  (2.5.uA..20.uA),
                            irange_200uA: (25.uA..200.uA),
                            irange_2mA:   (250.uA..2.mA),
                            irange_20mA:  (2.5.mA..20.mA),
                            irange_200mA: (25.mA..75.mA),
                            irange_700mA: (90.mA..110.mA), # This is verified on tester
                            irange_800mA: (90.mA..110.mA) } # This is verified on tester
            sink_fold_t = (300.uS..2.S)
            meter_irange = { irange_4uA:   4.uA,
                             irange_20uA:  20.uA,
                             irange_200uA: 200.uA,
                             irange_2mA:   2.mA,
                             irange_20mA:  20.mA,
                             irange_200mA: 200.mA,
                             irange_700mA: 700.mA,
                             irange_800mA: 800.mA }
            meter_vrange = 18.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-5.mV', pos: '0.001xSUPPLY+5.mV' }
            filter = [49, 98, 195, 391, 781, 1563, 3125, 6250, 12_500, 25_000, 50_000, 100_000, 200_000]
            bandwidth = (0..255)   # Integers
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'VHDVS+x2'  # also known as UVS256, High-Accuracy, Merged2
            forcev = (-2.V..18.V)
            irange = [4.uA, 20.uA, 200.uA, 2.mA, 20.mA, 40.mA, 200.mA, 400.mA]
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = { irange_4uA:   (500.nA..4.uA),
                              irange_20uA:  (2.5.uA..20.uA),
                              irange_200uA: (25.uA..200.uA),
                              irange_2mA:   (250.uA..2.mA),
                              irange_20mA:  (2.5.mA..20.mA),
                              irange_40mA:  (5.mA..40.mA),
                              irange_200mA: (25.mA..200.mA),
                              irange_400mA: (50.mA..400.mA) }
            source_fold_t = (300.uS..2.S)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = { irange_4uA:   (500.nA..4.uA),
                            irange_20uA:  (2.5.uA..20.uA),
                            irange_200uA: (25.uA..200.uA),
                            irange_2mA:   (250.uA..2.mA),
                            irange_20mA:  (2.5.mA..20.mA),
                            irange_40mA:  (5.mA..40.mA),
                            irange_200mA: (25.mA..75.mA),
                            irange_400mA: (50.mA..150.mA) }
            sink_fold_t = (300.uS..2.S)
            meter_irange = { irange_4uA:   4.uA,
                             irange_20uA:  20.uA,
                             irange_200uA: 200.uA,
                             irange_2mA:   2.mA,
                             irange_20mA:  20.mA,
                             irange_40mA:  40.mA,
                             irange_200mA: 200.mA,
                             irange_400mA: 400.mA }
            meter_vrange = 18.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-5.mV', pos: '0.001xSUPPLY+5.mV' }
            filter = [49, 98, 195, 391, 781, 1563, 3125, 6250, 12_500, 25_000, 50_000, 100_000, 200_000]
            bandwidth = (0..255)   # Integers
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'VHDVS_HC+x2'  # also known as UVS256, High-Current, High-Accuracy, Merged2
            forcev = (-2.V..18.V)
            irange = [4.uA, 20.uA, 200.uA, 2.mA, 20.mA, 40.mA, 200.mA, 400.mA, 700.mA, 1.4.A]
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = { irange_4uA:   (500.nA..4.uA),
                              irange_20uA:  (2.5.uA..20.uA),
                              irange_200uA: (25.uA..200.uA),
                              irange_2mA:   (250.uA..2.mA),
                              irange_20mA:  (2.5.mA..20.mA),
                              irange_40mA:  (5.mA..40.mA),
                              irange_200mA: (25.mA..200.mA),
                              irange_400mA: (50.mA..400.mA),
                              irange_700mA: (100.mA..700.mA),
                              irange_1p4A:  (200.mA..1.4.A) }
            source_fold_t = (300.uS..2.S)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = { irange_4uA:   (500.nA..4.uA),
                            irange_20uA:  (2.5.uA..20.uA),
                            irange_200uA: (25.uA..200.uA),
                            irange_2mA:   (250.uA..2.mA),
                            irange_20mA:  (2.5.mA..20.mA),
                            irange_40mA:  (5.mA..40.mA),
                            irange_200mA: (25.mA..75.mA),
                            irange_400mA: (50.mA..150.mA),
                            irange_700mA: (90.mA..110.mA), # This is verified on tester
                            irange_1p4A:  (190.mA..210.mA) } # This is verified on tester
            sink_fold_t = (300.uS..2.S)
            meter_irange = { irange_4uA:   4.uA,
                             irange_20uA:  20.uA,
                             irange_200uA: 200.uA,
                             irange_2mA:   2.mA,
                             irange_20mA:  20.mA,
                             irange_40mA:  40.mA,
                             irange_200mA: 200.mA,
                             irange_400mA: 400.mA,
                             irange_700mA: 700.mA,
                             irange_1p4A:  1.4.A }
            meter_vrange = 18.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-5.mV', pos: '0.001xSUPPLY+5.mV' }
            filter = [49, 98, 195, 391, 781, 1563, 3125, 6250, 12_500, 25_000, 50_000, 100_000, 200_000]
            bandwidth = (0..255)   # Integers
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'VHDVS_HC+x4'  # also known as UVS256, High-Current, High-Accuracy, Merged4
            forcev = (-2.V..18.V)
            irange = [4.uA, 20.uA, 200.uA, 2.mA, 20.mA, 200.mA, 700.mA, 2.8.A]
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = { irange_4uA:   (500.nA..4.uA),
                              irange_20uA:  (2.5.uA..20.uA),
                              irange_200uA: (25.uA..200.uA),
                              irange_2mA:   (250.uA..2.mA),
                              irange_20mA:  (2.5.mA..20.mA),
                              irange_200mA: (25.mA..200.mA),
                              irange_700mA: (100.mA..700.mA),
                              irange_2p8A:  (400.mA..2.8.A) }
            source_fold_t = (300.uS..2.S)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = { irange_4uA:   (500.nA..4.uA),
                            irange_20uA:  (2.5.uA..20.uA),
                            irange_200uA: (25.uA..200.uA),
                            irange_2mA:   (250.uA..2.mA),
                            irange_20mA:  (2.5.mA..20.mA),
                            irange_200mA: (25.mA..75.mA),
                            irange_700mA: (90.mA..110.mA), # This is verified on tester
                            irange_2p8A:  (390.mA..410.mA) } # This is verified on tester
            sink_fold_t = (300.uS..2.S)
            meter_irange = { irange_4uA:   4.uA,
                             irange_20uA:  20.uA,
                             irange_200uA: 200.uA,
                             irange_2mA:   2.mA,
                             irange_20mA:  20.mA,
                             irange_200mA: 200.mA,
                             irange_700mA: 700.mA,
                             irange_2p8A:  2.8.A }
            meter_vrange = 18.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-5.mV', pos: '0.001xSUPPLY+5.mV' }
            filter = [49, 98, 195, 391, 781, 1563, 3125, 6250, 12_500, 25_000, 50_000, 100_000, 200_000]
            bandwidth = (0..255)   # Integers
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          elsif @instrument == 'VHDVS_HC+x8'  # also known as UVS256, High-Current, High-Accuracy, Merged8
            forcev = (-2.V..18.V)
            irange = [4.uA, 20.uA, 200.uA, 2.mA, 20.mA, 200.mA, 700.mA, 5.6.A]
            source_overload_i = 'n/a'
            source_overload_t = 'n/a'
            source_fold_i = { irange_4uA:   (500.nA..4.uA),
                              irange_20uA:  (2.5.uA..20.uA),
                              irange_200uA: (25.uA..200.uA),
                              irange_2mA:   (250.uA..2.mA),
                              irange_20mA:  (2.5.mA..20.mA),
                              irange_200mA: (25.mA..200.mA),
                              irange_700mA: (100.mA..700.mA),
                              irange_5p6A:  (800.mA..5.6.A) }
            source_fold_t = (300.uS..2.S)
            sink_overload_i = 'n/a'
            sink_overload_t = 'n/a'
            sink_fold_i = { irange_4uA:   (500.nA..4.uA),
                            irange_20uA:  (2.5.uA..20.uA),
                            irange_200uA: (25.uA..200.uA),
                            irange_2mA:   (250.uA..2.mA),
                            irange_20mA:  (2.5.mA..20.mA),
                            irange_200mA: (25.mA..75.mA),
                            irange_700mA: (90.mA..110.mA), # This is verified on tester
                            irange_5p6A:  (790.mA..810.mA) } # This is verified on tester
            sink_fold_t = (300.uS..2.S)
            meter_irange = { irange_4uA:   4.uA,
                             irange_20uA:  20.uA,
                             irange_200uA: 200.uA,
                             irange_2mA:   2.mA,
                             irange_20mA:  20.mA,
                             irange_200mA: 200.mA,
                             irange_700mA: 700.mA,
                             irange_5p6A:  5.6.A }
            meter_vrange = 18.V
            tdelay = 0                     # default tdelay
            accuracy = { neg: '-0.001xSUPPLY-5.mV', pos: '0.001xSUPPLY+5.mV' }
            filter = [49, 98, 195, 391, 781, 1563, 3125, 6250, 12_500, 25_000, 50_000, 100_000, 200_000]
            bandwidth = (0..255)   # Integers
            supply.new(forcev, irange, source_overload_i, source_overload_t, source_fold_i,
                       source_fold_t, sink_overload_i, sink_overload_t, sink_fold_i,
                       sink_fold_t, meter_irange, meter_vrange, tdelay, accuracy, filter, bandwidth)
          else
            puts 'please enter an instrument type: e.g. $tester.ate_hardware("VSM").supply'
            puts 'Instrument type available: "VSM", "VSMx2", "VSMx4",'
            puts '"HexVS", "HexVSx2", "HexVSx4", "HexVSx6",'
            puts '"HexVS+", "HexVS+x2", "HexVS+x4", "HexVS+x6", "HDVS1",'
            puts '"HDVS1x2", "HDVS1x4", "VHDVS", "VHDVS_HC", "VHDVSx2",'
            puts '"VHDVS_HCx2", "VHDVS_HCx4", and "VHDVS_HCx8".'
            puts '"VHDVS+", "VHDVS_HC+", "VHDVS+x2",'
            puts '"VHDVS_HC+x2", "VHDVS_HC+x4", and "VHDVS_HC+x8".'
            puts 'HDVS1 is also known as HDVS.  VHDVS is also known as UVS256.'
            puts 'x2 is Merged2, x4 is Merged4, x6 is Merged6.  _HC is High-Current.'
            puts '+ is High-Accuracy.'
          end
        end
      end
    end
  end
end
