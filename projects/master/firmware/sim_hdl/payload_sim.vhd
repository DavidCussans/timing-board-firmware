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
	generic(
		CARRIER_TYPE: std_logic_vector(7 downto 0)
	);
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

	constant DESIGN_TYPE: std_logic_vector := X"00";

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal fmc_clk, rst_io, rsti, clk, rst, locked: std_logic;
	
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
			rst => rst_io
		);

-- Clock divider

	clkgen: entity work.pdts_rx_div_sim
		port map(
			sclk_o => fmc_clk,
			clk => clk,
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

	tx: entity work.master_top
		generic map(
			SIM => true
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_MASTER),
			ipb_out => ipbr(N_SLV_MASTER),
			mclk => fmc_clk,
			clk => clk,
			rst => rst,
			q => open
		);

end rtl;
