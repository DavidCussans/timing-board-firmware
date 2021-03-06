-- endpoint_wrapper
--
-- System-level wrapper for the PDTS endpoint block
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

use work.pdts_defs.all;

entity endpoint_wrapper_standalone is
	port(
		sysclk: in std_logic;
		rec_clk: in std_logic; -- CDR recovered clock
		rec_d: in std_logic; -- CDR recovered data (rec_clk domain)
		q: out std_logic;
		debug: out std_logic_vector(11 downto 0)
	);
		
end endpoint_wrapper_standalone;

architecture rtl of endpoint_wrapper_standalone is

	signal clkfb, clk_u, clk, locked: std_logic;
	signal ep_stat: std_logic_vector(3 downto 0);
	signal ep_rst, ep_clk, ep_rsto, ep_rdy, ep_v, ep_stb: std_logic;
	signal ep_scmd: std_logic_vector(SCMD_W - 1 downto 0);
	signal tstamp: std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
	signal evtctr: std_logic_vector(8 * EVTCTR_WDS - 1 downto 0);
	
	attribute MARK_DEBUG: string;
	attribute MARK_DEBUG of ep_stat, ep_rsto, ep_rdy, ep_scmd, ep_v, ep_stb, tstamp: signal is "TRUE";

begin

-- Startup reset

	mmcm: MMCME2_BASE
		generic map(
			CLKIN1_PERIOD => 20.0, -- 50MHz input
			CLKFBOUT_MULT_F => 20.0, -- 1GHz VCO freq
			CLKOUT0_DIVIDE_F => 20.0 -- 50MHz output
		)
		port map(
			clkin1 => sysclk,
			clkfbin => clkfb,
			clkout0 => clk_u,
			clkfbout => clkfb,
			locked => locked,
			rst => '0',
			pwrdwn => '0'
		);
		
	bufg_out: BUFG
		port map(
			i => clk_u,
			o => clk
	);

-- The endpoint

	ep_rst <= not locked;

	ep: entity work.pdts_endpoint
		generic map(
			SCLK_FREQ => 50.00
		)
		port map(
			sclk => clk,
			srst => ep_rst,
			addr => X"01",
			tgrp => "00",
			stat => ep_stat,
			rec_clk => rec_clk,
			rec_d => rec_d,
			txd => q,
			sfp_los => '0',
			cdr_los => '0',
			cdr_lol => '0',
			sfp_tx_dis => open,
			clk => open,
			rst => ep_rsto,
			rdy => ep_rdy,
			sync => ep_scmd,
			sync_stb => ep_stb,
			sync_first => ep_v,
			tstamp => tstamp,
			debug => debug
		);

end rtl;
