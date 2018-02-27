-- pdts_endpoint_sim
--
-- The timing endpoint design; simulated version
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

entity pdts_endpoint is
	generic(
		SCLK_FREQ: real := 50.0;
		EN_TX: boolean := false
	);
	port(
		sclk: in std_logic; -- Free-running system clock
		srst: in std_logic; -- System reset (sclk domain)
		addr: in std_logic_vector(7 downto 0); -- Endpoint address (async, sampled in clk domain)
		tgrp: in std_logic_vector(1 downto 0); -- Timing group (async, sampled in clk domain)
		stat: out std_logic_vector(3 downto 0); -- Status output (sclk domain)
		rec_clk: in std_logic; -- CDR recovered clock
		rec_d: in std_logic; -- CDR recovered data (rec_clk domain)
		txd: out std_logic; -- Output data to timing link (rec_clk domain)
		sfp_los: in std_logic; -- SFP LOS line (async, sampled in sclk domain)
		cdr_los: in std_logic; -- CDR LOS line (async, sampled in sclk domain)
		cdr_lol: in std_logic; -- CDR LOL line (async, sampled in sclk domain)
		sfp_tx_dis: out std_logic; -- SFP tx disable line (clk domain)
		clk: out std_logic; -- 50MHz clock output
		rst: out std_logic; -- 50MHz domain reset
		rdy: out std_logic; -- Timestamp valid flag
		sync: out std_logic_vector(SCMD_W - 1 downto 0); -- Sync command output (clk domain)
		sync_valid: out std_logic; -- Sync command valid flag (clk domain)
		tstamp: out std_logic_vector(8 * TSTAMP_WDS - 1 downto 0); -- Timestamp out
		tsync_in: in cmd_w := CMD_W_NULL;
		tsync_out: out cmd_r
	);

end pdts_endpoint;

architecture rtl of pdts_endpoint is

	signal rclk, rec_rst, rxphy_aligned, clk_i, rxphy_rst, rxphy_locked, rst_i: std_logic;
	signal rx_err: std_logic_vector(2 downto 0);
	signal phase_locked, phase_rst: std_logic;	
	signal stb, k, s_valid, s_stb, s_first: std_logic;
	signal d, dr: std_logic_vector(7 downto 0);
	signal rdy_i: std_logic;
	signal scmdw_v: cmd_w_array(1 downto 0);
	signal scmdr_v: cmd_r_array(1 downto 0);
	signal scmdw, acmdw: cmd_w;
	signal scmdr, acmdr: cmd_r;
	signal tx_q: std_logic_vector(7 downto 0);
	signal tx_err, tx_stb, tx_k: std_logic;

begin

-- Startup controller

	startup: entity work.pdts_ep_startup
		generic map(
			SCLK_FREQ => SCLK_FREQ,
			SIM => true
		)
		port map(
			sclk => sclk,
			srst => srst,
			stat => stat,
			sfp_los => sfp_los,
			cdr_los => cdr_los,
			cdr_lol => cdr_lol,
			rec_clk => rclk,
			rec_rst => rec_rst,
			rxphy_aligned => rxphy_aligned,
			clk => clk_i,
			rxphy_rst => rxphy_rst,
			rxphy_locked => rxphy_locked,
			rst => rst_i,
			rx_err => rx_err,
			rdy => rdy_i
		);
		
-- Clock divider

	clkgen: entity work.pdts_rx_div_sim
		generic map(
			INTERNAL_CLOCK => false
		)
		port map(
			sclk_i => rec_clk,
			sclk_o => rclk,
			clk => clk_i,
			phase_rst => phase_rst,
			phase_locked => phase_locked
		);
		
	clk <= clk_i;
	rst <= rst_i;
	
-- Rx PHY

	rxphy: entity work.pdts_rx_phy
		port map(
			fclk => sclk,
			rxclk => rclk,
			rxrst => rec_rst,
			rxd => rec_d,
			phase_rst => phase_rst,
			phase_locked => phase_locked,
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
	scmdw_v(0).req <= s_valid when dr(3 downto 0) = SCMD_ECHO else '0';
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
		
-- SFP control

	sfp_tx_dis <= '0' when EN_TX else '1';
		
end rtl;
