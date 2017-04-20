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
		sfp_los: in std_logic; -- SFP LOS line (async, sampled in sclk domain)
		cdr_los: in std_logic; -- CDR LOS line (async, sampled in sclk domain)
		cdr_lol: in std_logic -- CDR LOL line (async, sampled in sclk domain)
	);
		
end endpoint_wrapper;

architecture rtl of endpoint_wrapper is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ctrl_ep_en, ctrl_buf_rst, ctrl_ctr_rst: std_logic;
	signal ctrl_addr: std_logic_vector(3 downto 0);
	signal ctrl_tgrp: std_logic_vector(1 downto 0);
	signal ep_stat: std_logic_vector(3 downto 0);
	signal ep_rst, ep_clk, ep_rsto, ep_rdy, ep_v: std_logic;
	signal ep_scmd: std_logic_vector(SCMD_W - 1 downto 0);
	signal tstamp: std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
	signal evtctr: std_logic_vector(8 * EVTCTR_WDS - 1 downto 0);
	signal rob_q: std_logic_vector(31 downto 0);
	signal rob_rst, rob_we, rob_last: std_logic;
	signal buf_empty, buf_warn, buf_full, rob_full, rob_empty: std_logic;
	signal clkdiv: std_logic_vector(0 downto 0);
	signal ctr_rst: std_logic;
	signal t: std_logic_vector(2 ** SCMD_W - 1 downto 0);

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
	ctrl_buf_rst <= ctrl(0)(1);
	ctrl_ctr_rst <= ctrl(0)(2);
	ctrl_addr <= ctrl(0)(19 downto 16);
	ctrl_tgrp <= ctrl(0)(21 downto 20);
	stat(0) <= X"00000" & ep_stat & '0' & ep_rdy & ep_rsto & rob_empty & rob_full & buf_empty & buf_warn & buf_full;
	
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
			sfp_los => sfp_los,
			cdr_los => cdr_los,
			cdr_lol => cdr_lol,
			clk => ep_clk,
			rst => ep_rsto,
			rdy => ep_rdy,
			sync => ep_scmd,
			sync_v => ep_v,
			tstamp => tstamp,
			evtctr => evtctr
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

	evt: entity work.pdts_scmd_evt
		port map(
			clk => ep_clk,
			rst => ep_rsto,
			scmd => ep_scmd,
			valid => ep_v,
			tstamp => tstamp,
			evtctr => evtctr,
			empty => buf_empty,
			warn => buf_warn,
			full => buf_full,
			rob_clk => ipb_clk,
			rob_rst => rob_rst,
			rob_q => rob_q,
			rob_we => rob_we,
			rob_last => rob_last,
			rob_full => rob_full
		);
		
	rob_rst <= ipb_rst or ctrl_buf_rst;
		
	rob: entity work.pdts_rob
		generic map(
			N_FIFO => N_FIFO
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_BUF),
			ipb_out => ipbr(N_SLV_BUF),
			rst => rob_rst,
			d => rob_q,
			we => rob_we,
			last => rob_last,
			full => rob_full,
			empty => rob_empty
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

	process(ep_scmd) -- Unroll sync command
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
