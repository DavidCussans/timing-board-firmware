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
use work.ipbus_decode_master.all;

use work.pdts_defs.all;
use work.master_defs.all;

entity master is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		mclk: in std_logic;
		clk: in std_logic;
		rst: in std_logic;
		q: out std_logic;
		scmd_in: in cmd_w := CMD_W_NULL;
		scmd_out: out cmd_r
	);
		
end master;

architecture rtl of master is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal sel: std_logic_vector(calc_width(N_PART) - 1 downto 0);
	signal sctr: unsigned(3 downto 0) := X"0";
	signal stb: std_logic;
	signal spill: std_logic;
	signal tstamp: std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
	signal scmdw_v: cmd_w_array(N_CHAN + N_PART + 2 downto 0);
	signal scmdr_v: cmd_r_array(N_CHAN + N_PART + 2 downto 0);
	signal scmdw, acmdw: cmd_w;
	signal scmdr, acmdr: cmd_r;
	signal typ: std_logic_vector(SCMD_W - 1 downto 0);
	signal tv: std_logic;
	signal tgrp: std_logic_vector(N_PART - 1 downto 0);
	signal tx_q: std_logic_vector(7 downto 0);
	signal tx_err, tx_stb, tx_k: std_logic;
	
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
      sel => ipbus_sel_master(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
    
-- Global registers

	global: entity work.global
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_GLOBAL),
			ipb_out => ipbr(N_SLV_GLOBAL),
			clk => clk,
			rst => rst,
			tx_err => tx_err
		);
		
-- Strobe gen

	process(clk)
	begin
		if rising_edge(clk) then
			if sctr = (10 / SCLK_RATIO) - 1 then
				sctr <= X"0";
			else
				sctr <= sctr + 1;
			end if;
		end if;
	end process;
	
	stb <= '1' when sctr = 0 else '0';

-- Idle pattern gen

	idle: entity work.pdts_idle_gen
		port map(
			clk => clk,
			rst => rst,
			acmd_out => acmdw,
			acmd_in => acmdr
		);
		
-- Timestamp source

	tssrc: entity work.ts_source
		generic map(
			N_PART => N_PART
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_TSTAMP),
			ipb_out => ipbr(N_SLV_TSTAMP),
			clk => clk,
			rst => rst,
			tstamp => tstamp
		);
		
-- Timestamp broadcast

	ts: entity work.ts_bcast
		port map(
			clk => clk,
			rst => rst,
			tstamp => tstamp,
			scmd_out => scmdw_v(0),
			scmd_in => scmdr_v(0)
		);
		
-- Spill gate

	sgate: entity work.spill_gate
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_SPILL),
			ipb_out => ipbr(N_SLV_SPILL),
			clk => clk,
			rst => rst,
			spill => spill,
			scmd_out => scmdw_v(1),
			scmd_in => scmdr_v(1)
		);

-- Trigger command input

	scmdw_v(2) <= scmd_in;
	scmd_out <= scmdr_v(2);
	
-- Partitions

	pgen: for i in N_PART - 1 downto 0 generate
	
		part: entity work.partition
			port map(
				ipb_clk => ipb_clk,
				ipb_rst => ipb_rst,
				ipb_in => ipbw(i + N_SLV_PARTITION0),
				ipb_out => ipbr(i + N_SLV_PARTITION0),
				clk => clk,
				rst => rst,
				tstamp => tstamp,
				spill => spill,
				scmd_out => scmdw_v(i + 3),
				scmd_in => scmdr_v(i + 3),
				typ => typ,
				tv => tv,
				tack => tgrp(i)
			);
			
	end generate;
	
	npgen: for i in 3 downto N_PART generate -- Corresponds to address table max partitions
	
		ipbr(i + N_SLV_PARTITION0) <= IPB_RBUS_NULL;
			
	end generate;

-- Sync command gen

	gen: entity work.scmd_gen
		generic map(
			N_CHAN => N_CHAN
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_SCMD_GEN),
			ipb_out => ipbr(N_SLV_SCMD_GEN),
			clk => clk,
			rst => rst,
			tstamp => tstamp,
			scmd_out => scmdw_v(N_PART + 2 + N_CHAN downto N_PART + 3),
			scmd_in => scmdr_v(N_PART + 2 + N_CHAN downto N_PART + 3)
		);
		
-- Merge

	merge: entity work.pdts_scmd_merge
		generic map(
			N_SRC => N_CHAN + N_PART + 3,
			N_PART => N_PART
		)
		port map(
			clk => clk,
			rst => rst,
			scmd_in_v => scmdw_v,
			scmd_out_v => scmdr_v,
			typ => typ,
			tv => tv,
			tgrp => tgrp,
			scmd_out => scmdw,
			scmd_in => scmdr
		);
		
-- Tx

	tx: entity work.pdts_tx
		port map(
			clk => clk,
			rst => rst,
			stb => stb,
			addr => X"00",
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
			clk => clk,
			rst => rst,
			d => tx_q,
			k => tx_k,
			stb => tx_stb,
			txclk => mclk,
			q => q
		);

end rtl;
