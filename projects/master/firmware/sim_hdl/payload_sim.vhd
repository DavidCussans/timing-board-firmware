-- master
--
-- Interface to timing FMC v1 for PDTS blocks
--
-- All physical IO, clocks, etc go here
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_decode_top_sim.all;

entity payload_sim is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk125: in std_logic;
		nuke: out std_logic;
		soft_rst: out std_logic
	);

end payload_sim;

architecture rtl of payload_sim is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal fmc_clk, rec_clk, rec_d, sfp_dout, rst_io, rsti, clk, stb, rst, locked, q: std_logic;

	attribute IOB: string;
	attribute IOB of sfp_dout: signal is "TRUE";
	
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
      sel => ipbus_sel_top_sim(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- IO

	io: entity work.pdts_sim_io
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_IO),
			ipb_out => ipbr(N_SLV_IO),
			soft_rst => soft_rst,
			nuke => nuke,
			rst => rst_io
		);

-- Clock divider

	clkgen: entity work.pdts_sim_clk
		port map(
			sclk => fmc_clk,
			clk => clk,
			phase_rst => '0',
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

	tx: entity work.master
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_MASTER),
			ipb_out => ipbr(N_SLV_MASTER),
			mclk => fmc_clk,
			clk => clk,
			rst => rst,
			stb => stb,
			q => q
		);
		
	sfp_dout <= q when rising_edge(fmc_clk);

end rtl;
