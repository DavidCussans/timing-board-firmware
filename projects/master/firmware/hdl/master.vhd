-- master
--
-- The PDTS master timing block
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_tb_tx.all;
use work.pdts_defs.all;

entity master is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		mclk: in std_logic;
		locked: in std_logic;
		clk: in std_logic;
		stb: in std_logic;
		q: out std_logic
	);
		
end master;

architecture rtl of master is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ctrl_en, ctrl_clr: std_logic;
	signal clr, locked, clk, rsti, rstl, stb, en: std_logic;
	signal tstamp: std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
	signal evtctr: std_logic_vector(8 * EVTCTR_WDS - 1 downto 0);
	signal ts_gen_v, ts_gen_last, ts_gen_ack, trig_gen_v, trig_gen_last, trig_gen_ack: std_logic;
	signal ts_gen_d, trig_gen_d, async_d, sync_d, tx_d: std_logic_vector(7 downto 0);
	signal tx_err, async_last, async_ack, sync_rdy, sync_v, sync_ren, tx_stb, tx_k: std_logic;
	
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
      sel => ipbus_sel_tb_tx(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
    
-- Global registers

	global: entity work.master_global
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_GLOBAL),
			ipb_out => ipbr(N_SLV_GLOBAL),
			clk => clk,
			???
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

	stat(0) <= X"0000000" & "00" & tx_err & locked;
	ctrl_en <= ctrl(0)(0);
	ctrl_clr <= ctrl(0)(1);
		
-- Clock divider and reset CDC

	clkgen: entity work.master_clk
		port map(
			mclk => mclk,
			locked => locked,
			clk => clk,
			stb => stb
		);

	rstl <= rst or not locked;
	
	synchro: entity work.pdts_synchro
		generic map(
			N => 3
		)
		port map(
			clk => ipb_clk,
			clks => clk,
			d(0) => rstl,
			d(1) => ctrl_en,
			d(2) => ctrl_clr,
			q(0) => rsti,
			q(1) => en,
			q(2) => clr
		);

-- Pattern gen

	idle: entity work.pdts_idle_gen
		port map(
			clk => clk,
			rst => rsti,
			d => async_d,
			last => async_last,
			ack => async_ack
		);

-- Timestamp tx
		
	sync: entity work.pdts_ts_gen			
		port map(
			clk => clk,
			rst => rst,
			clr => '0',
			trig => trig,
			tstamp => tstamp,
			evtctr => evtctr,
			div => "00110",
			d => ts_d,
			v => ts_v,
			last => ts_last,
			ack => ts_ack,
			ren => sync_ren
		);

-- Command gen

	gen: entity work.pdts_trig_gen
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_TRIG_GEN),
			ipb_out => ipbr(N_SLV_TRIG_GEN),
			clk => clk,
			rst => rst,
			trig => trig,
			d => trig_gen_d,
			v => trig_gen_v,
			last => trig_gen_last,
			ack => trig_gen_ack,
			ren => sync_ren
		);

-- Merge

	merge: entity work.pdts_scmd_merge
		generic map(
			N_SRC => 2
		)
		port map(
			clk => clk,
			rst => rst,
			stb => stb,
			rdy => sync_rdy,
			d(7 downto 0) => trig_gen_d,
			d(15 downto 8) => ts_gen_d,
			dv(0) => trig_gen_v,
			dv(1) => ts_gen_v,
			last(0) => trig_gen_last,
			last(1) => ts_gen_last,
			ack(0) => trig_gen_ack,
			ack(1) => ts_gen_ack,
			ren => sync_ren,
			typ => open,
			tv => open,
			grp => X"F",
			q => sync_d,
			v => sync_v
		);
		
-- Tx

	tx: entity work.pdts_tx
		port map(
			clk => clk,
			rst => rsti,
			stb => stb,
			addr => X"AA",
			s_d => sync_d,
			s_valid => sync_v,
			s_rdy => sync_rdy,
			a_d => async_d,
			a_last => async_last,
			a_ack => async_ack,
			q => tx_d,
			k => tx_k,
			stbo => tx_stb,
			err => tx_err
		);
		
-- Tx PHY

	txphy: entity work.pdts_tx_phy
		port map(
			clk => clk,
			rst => rsti,
			d => tx_d,
			k => tx_k,
			stb => tx_stb,
			txclk => mclk,
			q => q
		);

end rtl;
