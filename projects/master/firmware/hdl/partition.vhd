-- partition
--
-- The PDTS master partition block
--
-- TODO: grabbing sync word...
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_partition.all;

use work.pdts_defs.all;
use work.master_defs.all;

entity partition is
	generic(
		PARTITION_ID: integer
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic;
		rst: in std_logic;
		tstamp: in std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		psync: in std_logic;
		spill: in std_logic;
		scmd_out_ts: out cmd_w;
		scmd_in_ts: in cmd_r;
		scmd_out_rs: out cmd_w;
		scmd_in_rs: in cmd_r;
		typ: in std_logic_vector(SCMD_W - 1 downto 0);
		tv: in std_logic;
		tack: out std_logic
	);
		
end partition;

architecture rtl of partition is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ctrl_part_en, ctrl_trig_en, ctrl_evtctr_rst, ctrl_trig_ctr_rst, ctrl_buf_en: std_logic;
	signal ctrl_cmd_mask: std_logic_vector(2 ** SCMD_W - 1 downto 0);
	signal cok, tok, trig, tack_i, erst, trst: std_logic;
	signal evtctr: std_logic_vector(8 * EVTCTR_WDS - 1 downto 0);
	signal t, tacc, trej: std_logic_vector(SCMD_MAX downto 0);
	signal rob_en_s, buf_empty, buf_err, rob_full, rob_empty, rob_warn: std_logic;
	signal rob_q: std_logic_vector(31 downto 0);
	signal rob_rst_u, rob_rst, rob_en, rob_we: std_logic;
	
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
      sel => ipbus_sel_partition(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
    
-- CSR

	csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CSR),
			ipb_out => ipbr(N_SLV_CSR),
			slv_clk => clk,
			d => stat,
			q => ctrl
		);

	ctrl_part_en <= ctrl(0)(0);
	ctrl_trig_en <= ctrl(0)(1);
	ctrl_evtctr_rst <= ctrl(0)(2);
	ctrl_trig_ctr_rst	<= ctrl(0)(3);
	ctrl_buf_en <= ctrl(0)(4);
	ctrl_cmd_mask <= ctrl(0)(31 downto 16);
	stat(0) <= X"000000" & "000" & rob_empty & rob_full & rob_warn & buf_empty & buf_err;
	
-- Command masks

	cok <= ctrl_cmd_mask(to_integer(unsigned(typ)));
	tok <= EVTCTR_MASK(to_integer(unsigned(typ)));
	tack_i <= tv and ctrl_part_en and (cok or scmd_in.ack) and (ctrl_trig_en or not tok);
	trig <= tv and ctrl_part_en and ctrl_trig_en and tok;
	tack <= tack_i;
	
	process(typ) -- Unroll typ
	begin
		for i in t'range loop
			if typ = std_logic_vector(to_unsigned(i, typ'length)) then
				t(i) <= '1';
			else
				t(i) <= '0';
			end if;
		end loop;
	end process;
	
	tacc <= t when (tv and tack_i) = '1' else (others => '0');
	trej <= t when (tv and not tack_i) = '1' else (others => '0');

-- Timestamp / event counter

	erst <= rst or ctrl_evtctr_rst or not ctrl_part_en;
	
	ereg: entity work.ipbus_ctrs_v
		generic map(
			CTR_WDS => EVTCTR_WDS / 4
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_EVTCTR),
			ipb_out => ipbr(N_SLV_EVTCTR),
			clk => clk,
			rst => erst,
			inc(0) => trig,
			q => evtctr
		);

	ts: entity work.pdts_ts_gen
		generic map(
			PARTITION_ID => PARTITION_ID,
			TS_RATE_RADIX => TS_RATE_RADIX
		)
		port map(
			clk => clk,
			rst => rst,
			tstamp => tstamp,
			evtctr => evtctr,
			scmd_out => scmd_out_ts,
			scmd_in => scmd_in_ts
		);
		
-- Run start / stop

	scmd_out_rs <= CMD_W_NULL;
		
-- Event buffer

	synchro: entity work.pdts_synchro
		generic map(
			N => 1
		)
		port map(
			clk => clk,
			clks => ipb_clk,
			d(0) => ctrl_buf_en,
			q(0) => rob_en_s
		);
		
	rob_rst_u <= ipb_rst or not rob_en_s;
		
	rsts: entity work.pdts_rst_stretch
		port map(
			clk => ipb_clk,
			rst => rob_rst_u,
			rsto => rob_rst,
			wen => rob_en
		);
	
	evt: entity work.pdts_scmd_evt
		port map(
			clk => clk,
			rst => rst,
			scmd => typ,
			valid => trig,
			tstamp => tstamp,
			evtctr => evtctr,
			empty => buf_empty,
			err => buf_err,
			rob_clk => ipb_clk,
			rob_rst => rob_rst,
			rob_en => rob_en,
			rob_q => rob_q,
			rob_we => rob_we,
			rob_full => rob_full
		);
		
	rob: entity work.pdts_rob
		generic map(
			N_FIFO => N_FIFO,
			WARN_HWM => N_FIFO * 1024 - 256,
			WARN_LWM => N_FIFO * 1024 - 512
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_BUF),
			ipb_out => ipbr(N_SLV_BUF),
			rst => rob_rst,
			d => rob_q,
			we => rob_we,
			full => rob_full,
			empty => rob_empty,
			warn => rob_warn
		);

-- Trigger counters

	trst <= rst or ctrl_trig_ctr_rst or not ctrl_part_en;
	
	actrs: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => t'length
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_ACTRS),
			ipb_out => ipbr(N_SLV_ACTRS),
			clk => clk,
			rst => trst,
			inc => tacc
		);

	rctrs: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => t'length
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_RCTRS),
			ipb_out => ipbr(N_SLV_RCTRS),
			clk => clk,
			rst => trst,
			inc => trej
		);	
	
end rtl;
