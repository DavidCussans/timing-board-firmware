-- payload_tlu
--
-- Wrapper for TLU design
--
-- Dave Newbold, July 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_decode_top_tlu.all;

entity payload is
	generic(
		CARRIER_TYPE: std_logic_vector(7 downto 0)
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		nuke: out std_logic;
		soft_rst: out std_logic;
		userled: out std_logic;
		clk125: in std_logic;
		clk_p: in std_logic; -- 50MHz master clock from PLL
		clk_n: in std_logic;
		rstb_clk: out std_logic; -- reset for PLL
		clk_lolb: in std_logic; -- PLL LOL
		trig_in_p: in std_logic_vector(5 downto 0);
		trig_in_n: in std_logic_vector(5 downto 0);
		q_hdmi_0: out std_logic; -- output to HDMI 0
		q_hdmi_1: out std_logic; -- output to HDMI 1
		q_hdmi_2: out std_logic; -- output to HDMI 2
		q_hdmi_3: out std_logic; -- output to HDMI 3
		d_hdmi_3: in std_logic; -- input from HDMI 3
		scl: out std_logic; -- main I2C
		sda: inout std_logic;
		rstb_i2c: out std_logic -- reset for I2C expanders
	);

end payload;

architecture rtl of payload is

	constant DESIGN_TYPE: std_logic_vector := X"00";

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal mclk, rst_io, rsti, clk, stb, rst, locked, q, d: std_logic;
	signal trig_in: std_logic_vector(5 downto 0);
	
begin

-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
		generic map(
    	NSLV => N_SLAVES,
    	SEL_WIDTH => IPBUS_SEL_WIDTH
    )
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      sel => ipbus_sel_top_tlu(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- IO

	io: entity work.pdts_tlu_io
		generic map(
			CARRIER_TYPE => CARRIER_TYPE,
			DESIGN_TYPE => DESIGN_TYPE
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_IO),
			ipb_out => ipbr(N_SLV_IO),
			soft_rst => soft_rst,
			nuke => nuke,
			rst => rst_io,
			locked => locked,
			clk_p => clk_p,
			clk_n => clk_n,
			clk => clk,
			mclk => mclk,
			rstb_clk => rstb_clk,
			clk_lolb => clk_lolb,
			trig_in_p => trig_in_p,
			trig_in_n => trig_in_n,
			trig_in => trig_in,
			q_hdmi => q,
			q_hdmi_0 => q_hdmi_0,
			q_hdmi_1 => q_hdmi_1,
			q_hdmi_2 => q_hdmi_2,
			q_hdmi_3 => q_hdmi_3,
			d_hdmi_3 => d_hdmi_3,
			d_hdmi => d,
			scl => scl,
			sda => sda,
			rstb_i2c => rstb_i2c
		);

-- Clock divider

	clkgen: entity work.pdts_rx_mul_mmcm
		port map(
			clk => clk,
			sclk => mclk,
			phase_rst => rst_io,
			phase_locked => locked
		);

	rsti <= rst_io or not locked;	
	
	synchro: entity work.pdts_synchro
		generic map(
			N => 1
		)
		port map(
			clk => ipb_clk,
			clks => clk,
			d(0) => rsti,
			q(0) => rst
		);

-- master block

	master: entity work.master_top
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_MASTER_TOP),
			ipb_out => ipbr(N_SLV_MASTER_TOP),
			mclk => mclk,
			clk => clk,
			rst => rst,
			spill_start => trig_in(4),
			spill_end => trig_in(3),
		  d => d,
			q => q
		);

end rtl;
