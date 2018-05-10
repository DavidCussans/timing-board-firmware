-- pdts_endpoint_upstream
--
-- The timing endpoint design - version for receiving data upstream, from trigger or via timing network
--
-- This part omits the MMCM and uses the 'upstream mode' alignment to save resources
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

entity pdts_endpoint_upstream is
	generic(
		SCLK_FREQ: real := 50.0 -- Frequency (MHz) of the supplied sclk
	);
	port(
		sclk: in std_logic; -- Free-running system clock
		srst: in std_logic; -- System reset (sclk domain)
		stat: out std_logic_vector(3 downto 0); -- Status output (sclk domain)
		rec_clk: in std_logic; -- CDR recovered clock from timing link
		rec_d: in std_logic; -- CDR recovered data from timing link (rec_clk domain)
		clk: in std_logic; -- 50MHz clock input
		rdy: out std_logic; -- Ready flag
		scmd: out cmd_w; -- Sync command out
		acmd: out cmd_w -- Async command out
	);

end pdts_endpoint_upstream;

architecture rtl of pdts_endpoint_upstream is

	signal rec_rst, rxphy_aligned, clk_i, rxphy_rst, rxphy_locked, rst_i: std_logic;
	signal rx_err: std_logic_vector(2 downto 0);
	signal stb, k, s_valid, s_valid_d, s_stb, s_first: std_logic;
	signal d, dr: std_logic_vector(7 downto 0);
	signal a_valid, a_last: std_logic;

begin

	clk_i <= clk;

-- Startup controller

	startup: entity work.pdts_ep_startup
		generic map(
			SCLK_FREQ => SCLK_FREQ
		)
		port map(
			sclk => sclk,
			srst => srst,
			stat => stat,
			sfp_los => '0',
			cdr_los => '0',
			cdr_lol => '0',
			rec_clk => rec_clk,
			rec_rst => rec_rst,
			rxphy_aligned => rxphy_aligned,
			clk => clk_i,
			rxphy_rst => rxphy_rst,
			rxphy_locked => rxphy_locked,
			rst => rst_i,
			rx_err => rx_err,
			rdy => '1'
		);

-- Rx PHY

	rxphy: entity work.pdts_rx_phy
		generic map(
			UPSTREAM_MODE => true
		)
		port map(
			fclk => sclk,
			fdel => "0000",
			cdel => "00000",
			rxclk => rec_clk,
			rxrst => rec_rst,
			rxd => rec_d,
			phase_locked => '1',
			aligned => rxphy_aligned,
			clk => clk_i,
			rst => rxphy_rst,
			rx_locked => rxphy_locked,
			q => d,
			k => k,
			stbo => stb
		);
		
-- Rx

	rx: entity work.pdts_rx
		generic map(
			NO_TGRP => true
		)
		port map(
			clk => clk_i,
			rst => rst_i,
			stb => stb,
			tgrp => "00",
			addr => X"00",
			d => d,
			k => k,
			q => dr,
			s_stb => s_stb,
			s_valid => s_valid,
			s_first => s_first,
			a_valid => a_valid,
			a_last => a_last,
			err => rx_err
		);

	scmd.d <= dr;
	scmd.req <= s_first;
	scmd.last <= '1'; -- Single word commands only on return channel (for now)

	acmd.d <= dr;
	acmd.req <= a_valid;
	acmd.last <= a_last;
	
	rdy <= rxphy_locked when rx_err = "000" else '0';
		
end rtl;
