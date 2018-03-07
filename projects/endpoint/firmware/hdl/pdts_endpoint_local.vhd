-- pdts_endpoint_local
--
-- The timing endpoint design - version for local use in loopback designs
--
-- This part omits the MMCM and uses the 'upstream mode' alignment to save resources
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

entity pdts_endpoint_local is
	generic(
		SCLK_FREQ: real := 50.0 -- Frequency (MHz) of the supplied sclk
	);
	port(
		sclk: in std_logic; -- Free-running system clock
		srst: in std_logic; -- System reset (sclk domain)
		addr: in std_logic_vector(7 downto 0); -- Endpoint address (async, sampled in clk domain)
		tgrp: in std_logic_vector(1 downto 0); -- Timing group (async, sampled in clk domain)
		stat: out std_logic_vector(3 downto 0); -- Status output (sclk domain)
		rec_clk: in std_logic; -- CDR recovered clock from timing link
		rec_d: in std_logic; -- CDR recovered data from timing link (rec_clk domain)
		txd: out std_logic; -- Output data to timing link (rec_clk domain)
		clk: in std_logic; -- 50MHz clock input
		rst: out std_logic; -- 50MHz domain reset
		rdy: out std_logic; -- Timestamp valid flag
		sync: out std_logic_vector(SCMD_W - 1 downto 0); -- Sync command output (clk domain)
		sync_stb: out std_logic; -- Sync command strobe (clk domain)
		sync_valid: out std_logic; -- Sync command valid flag (clk domain)
		tstamp: out std_logic_vector(8 * TSTAMP_WDS - 1 downto 0); -- Timestamp out
		tsync_in: in cmd_w := CMD_W_NULL; -- Tx sync command input
		tsync_out: out cmd_r -- Tx sync command handshake
	);

end pdts_endpoint_local;

architecture rtl of pdts_endpoint_local is

	signal rec_rst, rxphy_aligned, clk_i, rxphy_rst, rxphy_locked, rst_i: std_logic;
	signal rx_err: std_logic_vector(2 downto 0);
	signal phase_locked, phase_rst: std_logic;	
	signal stb, k, s_valid, s_valid_d, s_stb, s_first: std_logic;
	signal d, dr: std_logic_vector(7 downto 0);
	signal rdy_i: std_logic;
	signal scmdw_v: cmd_w_array(1 downto 0);
	signal scmdr_v: cmd_r_array(1 downto 0);
	signal scmdw, acmdw: cmd_w;
	signal scmdr, acmdr: cmd_r;
	signal tp, tp_d: std_logic;
	signal tx_q: std_logic_vector(7 downto 0);
	signal tx_err, tx_stb, tx_k: std_logic;

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
			rdy => rdy_i
		);
		
	rst <= rst_i;
				
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
		port map(
			clk => clk_i,
			rst => rst_i,
			stb => stb,
			tgrp => tgrp,
			addr => addr,
			d => d,
			k => k,
			q => dr,
			s_stb => s_stb,
			s_valid => s_valid,
			s_first => s_first,
			a_valid => open,
			a_last => open,
			err => rx_err
		);
	
-- Temporary sync output

	sync <= dr(SCMD_W - 1 downto 0);
	sync_valid <= s_first and rdy_i;
	sync_stb <= s_stb and rdy_i;
	
-- Timestamp / event counter

	ts: entity work.pdts_tstamp
		port map(
			clk => clk_i,
			rst => rst_i,
			d => dr,
			s_stb => s_stb,
			s_first => s_first,
			tstamp => tstamp,
			rdy => rdy_i
		);
		
	rdy <= rdy_i;
	
-- Echo command; send it back to the master

	scmdw_v(0).d <= dr;
	scmdw_v(0).req <= s_valid and s_stb when dr(3 downto 0) = SCMD_ECHO else '0';
	scmdw_v(0).last <= '1';

-- Sync command input

	scmdw_v(1) <= tsync_in;
	tsync_out <= scmdr_v(1);

-- Merge

	merge: entity work.pdts_scmd_merge
		generic map(
			N_SRC => 2,
			N_PART => 0
		)
		port map(
			clk => clk_i,
			rst => rst_i,
			scmd_in_v => scmdw_v,
			scmd_out_v => scmdr_v,
			typ => open,
			tv => open,
			tgrp => (others => '0'),
			scmd_out => scmdw,
			scmd_in => scmdr
		);
		
-- Idle pattern gen

	idle: entity work.pdts_idle_gen
		port map(
			clk => clk_i,
			rst => rst_i,
			acmd_out => acmdw,
			acmd_in => acmdr
		);
		
-- Tx

	tx: entity work.pdts_tx
		port map(
			clk => clk_i,
			rst => rst_i,
			stb => stb,
			addr => addr,
			scmd_in => scmdw,
			scmd_out => scmdr,
			acmd_in => acmdw,
			acmd_out => acmdr,
			q => tx_q,
			k => tx_k,
			stbo => tx_stb,
			err => tx_err
		);
		
-- Tx PHY

	txphy: entity work.pdts_tx_phy
		port map(
			clk => clk_i,
			rst => rst_i,
			d => tx_q,
			k => tx_k,
			stb => tx_stb,
			txclk => rec_clk,
			q => txd
		);
		
end rtl;
