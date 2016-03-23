Resources.create do

  pinmap :pinmap_test

  timing_sheet_pins = [:tclk, :tdi, :tdo, :tms]

  # Define some edge options so we can define some Edge objects
  default_options = {
    d_src:   'PAT',                    # source of the channel drive data (e.g. pattern, drive_hi, drive_lo, etc.)
    d_fmt:   'NR',                     # drive data format (NR, RL, RH, etc.)
    d0_edge: 'd1_edge',                # time at which the input drive is turned on
    d1_edge: 'clkre + 0.25 * cycle',   # time of the initial data drive edge
    d2_edge: '',                       # time of the return format data drive edge
    d3_edge: '',                       # time at which the input drive is turned off
    c_mode:  'Edge',                   # output compare mode
    c1_edge: 'clkre + 0.75 * cycle',   # time of the initial output compare edge
    c2_edge: '',                       # time of the final output compare edge (window compare)
    t_res:   'Machine',                # timing resolution (possibly ATE-specific)
    clk_per: ''                        # clock period equation - for use with MCG
  }
  clock_options = {
    d_src:   'PAT',                    # source of the channel drive data (e.g. pattern, drive_hi, drive_lo, etc.)
    d_fmt:   'RL',                     # drive data format (NR, RL, RH, etc.)
    d0_edge: 'd1_edge',                # time at which the input drive is turned on
    d1_edge: 'clkre',                  # time of the initial data drive edge
    d2_edge: 'clkre + 0.5 * cycle',    # time of the return format data drive edge
    d3_edge: '',                       # time at which the input drive is turned off
    c_mode:  'Off',                    # output compare mode
    c1_edge: '',                       # time of the initial output compare edge
    c2_edge: '',                       # time of the final output compare edge (window compare)
    t_res:   'Machine',                # timing resolution (possibly ATE-specific)
    clk_per: 'mcg_cycle'               # clock period equation - for use with MCG
  }
  input_options = {
    d_src:   'PAT',                    # source of the channel drive data (e.g. pattern, drive_hi, drive_lo, etc.)
    d_fmt:   'NR',                     # drive data format (NR, RL, RH, etc.)
    d0_edge: 'd1_edge',                # time at which the input drive is turned on
    d1_edge: 'clkre - jtag_su',        # time of the initial data drive edge
    d2_edge: '',                       # time of the return format data drive edge
    d3_edge: '',                       # time at which the input drive is turned off
    c_mode:  'Off',                    # output compare mode
    c1_edge: '',                       # time of the initial output compare edge
    c2_edge: '',                       # time of the final output compare edge (window compare)
    t_res:   'Machine',                # timing resolution (possibly ATE-specific)
    clk_per: ''                        # clock period equation - for use with MCG
  }
  output_options = {
    d_src:   'PAT',                    # source of the channel drive data (e.g. pattern, drive_hi, drive_lo, etc.)
    d_fmt:   'NR',                     # drive data format (NR, RL, RH, etc.)
    d0_edge: 'd1_edge',                # time at which the input drive is turned on
    d1_edge: 'clkre',                  # time of the initial data drive edge
    d2_edge: '',                       # time of the return format data drive edge
    d3_edge: '',                       # time at which the input drive is turned off
    c_mode:  'Edge',                   # output compare mode
    c1_edge: 'clkre + jtag_ov',        # time of the initial output compare edge
    c2_edge: '',                       # time of the final output compare edge (window compare)
    t_res:   'Machine',                # timing resolution (possibly ATE-specific)
    clk_per: ''                        # clock period equation - for use with MCG
  }

  # Define the Edge objects that you want to use later to construct edgesets/timesets
  #  * the interface puts these in 'edge_collection'
  # FORMAT: edge <timing category>, <pin_name/type>, <edge options>
  edge :default, :default, default_options
  edge :clock, :clk, clock_options
  edge :input, :default, input_options
  edge :output, :default, output_options

  # Assign edges to the pins for edgeset sheet ':func'
  #   * assign all pins some default timing for starters...
  #   * importing edgesets will automatically populate ac_specset variables contained within the equations
  # FORMAT: edgeset <edgeset sheet name>, edgeset: <edgeset>, pin: <pin_name>, edge: <edge_object>, es_sheet_pins: <array of pins>, spec_sheet: <AC specsheet name>
  edgeset :func, edgeset: :default, pin: :tclk, edge: edge_collection.edges[:default][:default], spec_sheet: :func, es_sheet_pins: timing_sheet_pins
  edgeset :func, edgeset: :default, pin: :tms,  edge: edge_collection.edges[:default][:default], spec_sheet: :func
  edgeset :func, edgeset: :default, pin: :tdi,  edge: edge_collection.edges[:default][:default], spec_sheet: :func
  edgeset :func, edgeset: :default, pin: :tdo,  edge: edge_collection.edges[:default][:default], spec_sheet: :func
  #   * now assign pins some more meaningful timing for JTAG operation...
  edgeset :func, edgeset: :es_jtag, pin: :tclk, edge: edge_collection.edges[:clock][:clk], spec_sheet: :func, es_sheet_pins: timing_sheet_pins
  edgeset :func, edgeset: :es_jtag, pin: :tms,  edge: edge_collection.edges[:input][:default], spec_sheet: :func
  edgeset :func, edgeset: :es_jtag, pin: :tdi,  edge: edge_collection.edges[:input][:default], spec_sheet: :func
  edgeset :func, edgeset: :es_jtag, pin: :tdo,  edge: edge_collection.edges[:output][:default], spec_sheet: :func

  # Assign edges to the pins for timeset sheet ':func'
  #   * first a :default timeset
  # FORMAT: timeset <timset sheet name>, timeset: <timeset>, pin: <pin_name>, eset: <edgeset name>, ts_sheet_pins: <array of pins>
  timeset :func, timeset: :default, pin: :tclk, eset: :default, ts_sheet_pins: timing_sheet_pins
  timeset :func, timeset: :default, pin: :tms,  eset: :default
  timeset :func, timeset: :default, pin: :tdi,  eset: :default
  timeset :func, timeset: :default, pin: :tdo,  eset: :default
  #   * now a :jtag timeset
  timeset :func, timeset: :jtag, pin: :tclk, eset: :es_jtag, ts_sheet_pins: timing_sheet_pins
  timeset :func, timeset: :jtag, pin: :tms,  eset: :es_jtag
  timeset :func, timeset: :jtag, pin: :tdi,  eset: :es_jtag
  timeset :func, timeset: :jtag, pin: :tdo,  eset: :es_jtag

  #   * now define a few more AC specs and values
  ac_specset :func, 'cycle', specset: :func_100MHz, nom: { min: '9*ns', typ: '10*ns', max: '11*ns' }
  ac_specset :func, 'cycle', specset: :func_125MHz, nom: { min: '7*ns', typ: '8*ns', max: '9*ns' }
  ac_specset :func, 'new_var1', specset: :func_100MHz, nom: { min: '1*ns', typ: '2*ns', max: '3*ns' }
  ac_specset :func, 'new_var2', specset: :func_125MHz, nom: { min: '4*ns', typ: '5*ns', max: '6*ns' }

  level_sheet_pins = [:vdd1, :vdd2, :tclk, :tdi, :tdo, :tms]

  # Define some level options so we can define some Level objects
  pwr_options = {
    vmain: 'vdd_main_val',            # Main supply voltage
    valt:  'vdd_alt_val',             # Alternate supply voltage
    ifold: 'fold_val',                # Supply clamp current
    delay: 'delay_val'                # Supply power-up delay
  }
  se_pin_options1 = {
    vil:       'pin_supply * 0.25',   # Input drive low
    vih:       'pin_supply * 0.75',   # Input drive high
    vol:       'pin_supply * 0.45',   # Output compare low
    voh:       'pin_supply * 0.55',   # Output compare high
    vcl:       'vclamp_low',          # Voltage clamp low
    vch:       'vclamp_low',          # Voltage clamp high
    vt:        'pin_supply * 0.50',   # Termination voltage
    voutlotyp: '0',            #
    vouthityp: '0',            #
    dmode:     'Largeswing-VT' # Driver mode (possibly ATE-specific)
  }
  se_pin_options2 = {
    vil:       'pin_supply * 0.10',   # Input drive low
    vih:       'pin_supply * 0.90',   # Input drive high
    vol:       'pin_supply * 0.50',   # Output compare low
    voh:       'pin_supply * 0.50',   # Output compare high
    vcl:       'vclamp_low',          # Voltage clamp low
    vch:       'vclamp_low',          # Voltage clamp high
    vt:        'pin_supply * 0.50',   # Termination voltage
    voutlotyp: '0',            #
    vouthityp: '0',            #
    dmode:     'Largeswing-VT' # Driver mode (possibly ATE-specific)
  }

  # Define the Level objects that you want to use later to construct edgesets/timesets
  #  * the interface puts these in 'level_collection'
  # FORMAT: level <level category>, <level options>
  pwr_level :pwr, pwr_options
  pin_level_se :pin_type1, se_pin_options1
  pin_level_se :pin_type2, se_pin_options2

  # Assign levels to the pins for levelset sheet ':func'
  #   * assign all pins some default levels for starters...
  #   * importing levelsets will automatically populate dc_specset variables contained within the equations
  # FORMAT: levelset <levelset sheet name>, pin: <pin_name>, level: <level_object>, es_sheet_pins: <array of pins>, spec_sheet: <AC specsheet name>
  levelset :func, pin: :vdd1, level: level_collection.pwr_group[:pwr], spec_sheet: :func, ls_sheet_pins: level_sheet_pins
  levelset :func, pin: :vdd2, level: level_collection.pwr_group[:pwr], spec_sheet: :func
  levelset :func, pin: :tclk, level: level_collection.pin_group[:pin_type1], spec_sheet: :func
  levelset :func, pin: :tms,  level: level_collection.pin_group[:pin_type2], spec_sheet: :func
  levelset :func, pin: :tdi,  level: level_collection.pin_group[:pin_type1], spec_sheet: :func
  levelset :func, pin: :tdo,  level: level_collection.pin_group[:pin_type2], spec_sheet: :func

  #   * now define a few more AC specs and values
  dc_specset :func, 'vdd_main_val', specset: :power_down_levels, min: { min: '0.1*V' }, nom: { typ: '0.2*V' }, max: { max: '0.3*V' }
  dc_specset :func, 'vdd_alt_val',  specset: :power_down_levels, min: { min: '7*V' },   nom: { typ: '8*V' },   max: { max: '9*V' }
  dc_specset :func, 'current1',     specset: :power_up_levels,   min: { min: '1*mA' },  nom: { typ: '2*mA' },  max: { max: '3*mA' }
  dc_specset :func, 'voltage1',     specset: :power_up_levels,   min: { min: '4*mV' },  nom: { typ: '5*mV' },  max: { max: '6*mV' }
end
