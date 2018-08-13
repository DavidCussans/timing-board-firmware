set_property BITSTREAM.Config.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

create_clock -period 20.000 -name clk [get_ports clk_p]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk] -group [get_clocks -include_generated_clocks -of_obj [get_pins -of_obj [get_cells infra/clocks/mmcm] -filter {NAME =~ *CLKOUT*}]]

set_property IOSTANDARD LVDS_25 [get_port {clk_p clk_n}]
set_property PACKAGE_PIN T5 [get_ports {clk_p}]
set_property PACKAGE_PIN T4 [get_ports {clk_n}]

set_property IOSTANDARD TMDS_33 [get_port {q_sfp_* d_cdr_*}]
set_property PACKAGE_PIN F1 [get_ports {q_sfp_p}]
set_property PACKAGE_PIN E1 [get_ports {q_sfp_n}]
set_property PACKAGE_PIN J3 [get_ports {d_cdr_p}]
set_property PACKAGE_PIN J2 [get_ports {d_cdr_n}]
set_property PULLUP TRUE [get_ports {q_sfp_*}]
false_path {q_sfp_* d_cdr_*} sysclk

set_property IOSTANDARD LVCMOS33 [get_port {q_hdmi_* d_hdmi_* rstb_clk clk_lolb rstb_i2c sfp_* cdr_*}]
set_property PACKAGE_PIN R7 [get_ports {q_hdmi_0}]
set_property PACKAGE_PIN U4 [get_ports {q_hdmi_1}]
set_property PACKAGE_PIN R8 [get_ports {q_hdmi_2}]
set_property PACKAGE_PIN K5 [get_ports {q_hdmi_3}]
set_property PACKAGE_PIN G3 [get_ports {d_hdmi_3}]
set_property PACKAGE_PIN C1 [get_ports {rstb_clk}]
set_property PACKAGE_PIN G6 [get_ports {clk_lolb}]
set_property PACKAGE_PIN C2 [get_ports {rstb_i2c}]
set_property PACKAGE_PIN G2 [get_ports {sfp_los}]
set_property PACKAGE_PIN H2 [get_ports {sfp_fault}]
set_property PACKAGE_PIN H6 [get_ports {sfp_tx_dis}]
set_property PACKAGE_PIN D7 [get_ports {cdr_lol}]
set_property PACKAGE_PIN E7 [get_ports {cdr_los}]
false_path {q_hdmi_* d_hdmi_* rstb_clk clk_lolb rstb_i2c sfp_* cdr_*} sysclk

set_property IOSTANDARD LVCMOS25 [get_port {scl sda}]
set_property PACKAGE_PIN N17 [get_ports {scl}]
set_property PACKAGE_PIN P18 [get_ports {sda}]
false_path {scl sda} sysclk
