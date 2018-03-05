-- endpoint_wrapper
--
-- System-level wrapper for the PDTS endpoint block
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_endpoint_wrapper.all;

use work.pdts_defs.all;
use work.wrapper_defs.all;

entity endpoint_wrapper is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		rec_clk: in std_logic; -- CDR recovered clock
		rec_d: in std_logic; -- CDR recovered data (rec_clk domain)
		txd: out std_logic; -- Output data to timing link (rec_clk domain)
		sfp_los: in std_logic; -- SFP LOS line (async, sampled in sclk domain)
		cdr_los: in std_logic; -- CDR LOS line (async, sampled in sclk domain)
		cdr_lol: in std_logic; -- CDR LOL line (async, sampled in sclk domain)
		sfp_tx_dis: out std_logic -- SFP tx disable line (clk domain)
	);
		
end endpoint_wrapper;

architecture rtl of endpoint_wrapper is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl, ctrl_cmd: ipb_reg_v(0 downto 0);
	signal stat, stat_cmd: ipb_reg_v(0 downto 0);
	signal stb_cmd: std_logic_vector(0 downto 0);
	signal ctrl_ep_en, ctrl_buf_en, ctrl_ctr_rst, ctrl_mask_dis: std_logic;
	signal ctrl_addr: std_logic_vector(7 downto 0);
	signal ctrl_tgrp: std_logic_vector(1 downto 0);
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
	ctrl_buf_en <= ctrl(0)(1);
	ctrl_ctr_rst <= ctrl(0)(2);
	ctrl_tgrp <= ctrl(0)(5 downto 4);
	ctrl_mask_dis <= ctrl(0)(6);
	ctrl_addr <= ctrl(0)(15 downto 8);
	stat(0) <= X"00000" & "00" & in_run & in_spill & ep_stat & ep_rdy & ep_rsto & buf_warn & buf_err;

-- Sync command tx control

	cmd: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CMD),
			ipb_out => ipbr(N_SLV_CMD),
			slv_clk => ep_clk,
			d => stat_cmd,
			q => ctrl_cmd,
			stb => stb_cmd
		);
		
	tsync_in <= (ctrl_cmd(0)(7 downto 0), stb_cmd(0), '1');
	stat_cmd(0) <= X"0000000" & "000" & tsync_out.ack when rising_edge(ep_clk) and stb_cmd(0) = '1';
	
-- The endpoint

	ep_rst <= ipb_rst or not ctrl_ep_en;

	ep: entity work.pdts_endpoint
		generic map(
			SCLK_FREQ => 31.25
		)
		port map(
			sclk => ipb_clk,
			srst => ep_rst,
			addr => ctrl_addr,
			tgrp => ctrl_tgrp,
			stat => ep_stat,
			rec_clk => rec_clk,
			rec_d => rec_d,
			txd => txd,
			sfp_los => sfp_los,
			cdr_los => cdr_los,
			cdr_lol => cdr_lol,
			clk => ep_clk,
			rst => ep_rsto,
			rdy => ep_rdy,
			sync => ep_scmd,
			sync_valid => ep_v,
			tstamp => tstamp,
			tsync_in => tsync_in,
			tsync_out => tsync_out
		);
		
-- Timestamp

	tsamp: entity work.ipbus_ctrs_samp
		generic map(
			N_CTRS => 1,
			CTR_WDS => TSTAMP_WDS / 4
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_TSTAMP),
			ipb_out => ipbr(N_SLV_TSTAMP),
			clk => ep_clk,
			d => tstamp
		);
		
-- Decoder

	decode:entity work.pdts_ep_decoder
		port map(
			clk => ep_clk,
			rst => ep_rsto,
			rdy => ep_rdy,
			scmd => ep_scmd,
			scmd_v => ep_v,
			in_spill => in_spill,
			in_run => in_run,
			evtctr => evtctr
		);

-- Event counter

	esamp: entity work.ipbus_ctrs_samp
		generic map(
			N_CTRS => 1,
			CTR_WDS => EVTCTR_WDS / 4
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_EVTCTR),
			ipb_out => ipbr(N_SLV_EVTCTR),
			clk => ep_clk,
			d => evtctr
		);
		
-- Buffer

	trig <= ep_v and (EVTCTR_MASK(to_integer(unsigned(ep_scmd(3 downto 0)))) or ctrl_mask_dis);

	rob: entity work.pdts_mon_buf
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_BUF),
			ipb_out => ipbr(N_SLV_BUF),
			en => ctrl_buf_en,
			clk => ep_clk,
			rst => ep_rsto,
			scmd => ep_scmd,
			scmd_v => trig,
			tstamp => tstamp,
			evtctr => evtctr,
			warn => buf_warn,
			err => buf_err
		);

-- Frequency counter

	div: entity work.freq_ctr_div
		generic map(
			N_CLK => 1
		)
		port map(
			clk(0) => ep_clk,
			clkdiv => clkdiv
		);

	ctr: entity work.freq_ctr
		generic map(
			N_CLK => 1
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_FREQ),
			ipb_out => ipbr(N_SLV_FREQ),
			clkdiv => clkdiv
		);

-- Trigger counters

	process(ep_scmd, ep_v) -- Unroll sync command
	begin
		for i in t'range loop
			if ep_scmd = std_logic_vector(to_unsigned(i, ep_scmd'length)) and ep_v = '1' then
				t(i) <= '1';
			else
				t(i) <= '0';
			end if;
		end loop;
	end process;

	ctr_rst <= ipb_rst or ctrl_ctr_rst;

	ctrs: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => t'length
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CTRS),
			ipb_out => ipbr(N_SLV_CTRS),
			clk => ep_clk,
			rst => ctr_rst,
			inc => t
		);

end rtl;
