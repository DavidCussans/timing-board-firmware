-- endpoint_wrapper_lite
--
-- Minimal wrapper for the PDTS endpoint block
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_endpoint_wrapper_lite.all;

use work.pdts_defs.all;
use work.wrapper_defs.all;

entity endpoint_wrapper_lite is
	generic(
		SIM: boolean := false
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		addr: in std_logic_vector(7 downto 0);
		rec_clk: in std_logic; -- CDR recovered clock
		rec_d: in std_logic; -- CDR recovered data (rec_clk domain)
		clk: out std_logic;
		rst: out std_logic;
		txd: out std_logic; -- Output data to timing link (rec_clk domain)
		sfp_los: in std_logic; -- SFP LOS line (async, sampled in sclk domain)
		cdr_los: in std_logic; -- CDR LOS line (async, sampled in sclk domain)
		cdr_lol: in std_logic; -- CDR LOL line (async, sampled in sclk domain)
		sfp_tx_dis: out std_logic -- SFP tx disable line (clk domain)
	);
		
end endpoint_wrapper_lite;

architecture rtl of endpoint_wrapper_lite is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl, ctrl_cmd: ipb_reg_v(0 downto 0);
	signal stat, stat_cmd: ipb_reg_v(0 downto 0);
	signal stb_cmd: std_logic_vector(0 downto 0);
	signal ctrl_ep_en, ctrl_buf_en, ctrl_ctr_rst, ctrl_mask_dis, ctrl_int_addr: std_logic;
	signal ctrl_addr: std_logic_vector(7 downto 0);
	signal ctrl_tgrp: std_logic_vector(1 downto 0);
	signal addr_ep: std_logic_vector(7 downto 0);
	signal ep_stat: std_logic_vector(3 downto 0);
	signal ep_rst, ep_clk, ep_rsto, ep_rdy, ep_v: std_logic;
	signal ep_scmd: std_logic_vector(SCMD_W - 1 downto 0);
	signal tsync_in: cmd_w;
	signal tsync_out: cmd_r;
	signal tstamp: std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
	signal evtctr: std_logic_vector(8 * EVTCTR_WDS - 1 downto 0);
	signal trig, buf_warn, buf_err, in_run, in_spill: std_logic;
	signal clkdiv: std_logic_vector(0 downto 0);
	signal ctr_rst: std_logic;
	signal t: std_logic_vector(SCMD_MAX downto 0);

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
      sel => ipbus_sel_endpoint_wrapper(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- Version

	ver: entity work.ipbus_roreg_v
		generic map(
			N_REG => 1,
			DATA => WRAPPER_VERSION
		)
		port map(
			ipb_in => ipbw(N_SLV_VERSION),
			ipb_out => ipbr(N_SLV_VERSION)
		);

-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl
		);

	ctrl_ep_en <= ctrl(0)(0);
	ctrl_tgrp <= ctrl(0)(5 downto 4);
	stat(0) <= X"000000" & "000" & ep_rdy & ep_stat;

-- The endpoint

	ep: entity work.pdts_endpoint
		generic map(
			SCLK_FREQ => 31.25,
			SIM => SIM
		)
		port map(
			sclk => ipb_clk,
			srst => ctrl_ep_en,
			addr => addr,
			tgrp => ctrl_tgrp,
			stat => ep_stat,
			rec_clk => rec_clk,
			rec_d => rec_d,
			txd => txd,
			sfp_los => sfp_los,
			cdr_los => cdr_los,
			cdr_lol => cdr_lol,
			clk => clk,
			rst => rst,
			rdy => open,
			sync => open,
			sync_first => open,
			tstamp => open,
	???		tsync_in => tsync_in,
	???		tsync_out => tsync_out
		);

end rtl;
