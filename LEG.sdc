create_clock -name "CLOCK_50" -period 20.000ns [get_ports {i_clk}]
derive_pll_clocks
derive_clock_uncertainty