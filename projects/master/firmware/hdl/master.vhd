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
		q: out std_logic
	);
		
end master;

architecture rtl of master is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal sel: std_logic_vector(calc_width(N_PART) - 1 downto 0);
	signal en: std_logic;
	signal sctr: unsigned(3 downto 0) := X"0";
	signal stb: std_logic;
	signal tstamp: std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
	signal evtctr: std_logic_vector(8 * EVTCTR_WDS - 1 downto 0);
	signal scmdw_v: cmd_w_array(N_PART downto 0);
	signal scmdr_v: cmd_r_array(N_PART downto 0);
	signal scmdw, acmdw: cmd_w;
	signal scmdr, acmdr: cmd_r;
	signal ipbw_p: ipb_wbus_array(N_PART - 1 downto 0);
	signal ipbr_p: ipb_rbus_array(N_PART - 1 downto 0);
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
			tx_err => tx_err,
			part_sel => sel,
			en => en,
			tstamp => tstamp
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

-- Sync command gen

	gen: entity work.pdts_scmd_gen
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_SCMD_GEN),
			ipb_out => ipbr(N_SLV_SCMD_GEN),
			clk => clk,
			rst => rst,
			tstamp => tstamp,
			scmd_out => scmdw_v(0),
			scmd_in => scmdr_v(0)
		);
		
-- Partitions

	fabric_p: entity work.ipbus_fabric_sel
		generic map(
			NSLV => N_PART,
			SEL_WIDTH => sel'length
		)
		port map(
			ipb_in => ipbw(N_SLV_PARTITION),
			ipb_out => ipbr(N_SLV_PARTITION),
			sel => sel,
			ipb_to_slaves => ipbw_p,
			ipb_from_slaves => ipbr_p
		);
				
	pgen: for i in N_PART - 1 downto 0 generate
	
		part: entity work.partition
			generic map(
				PARTITION_ID => i
			)
			port map(
				ipb_clk => ipb_clk,
				ipb_rst => ipb_rst,
				ipb_in => ipbw_p(i),
				ipb_out => ipbr_p(i),
				clk => clk,
				rst => rst,
				tstamp => tstamp,
				scmd_out => scmdw_v(i + 1),
				scmd_in => scmdr_v(i + i),
				typ => typ,
				tv => tv,
				tack => tgrp(i)
			);
			
	end generate;
		
-- Merge

	merge: entity work.pdts_scmd_merge
		generic map(
			N_SRC => N_PART + 1
		)
		port map(
			clk => clk,
			rst => rst,
			stb => stb,
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
			addr => X"AA",
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
