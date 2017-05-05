-- global
--
-- Global (non-partition-specific) control registers for PDTS master
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_global.all;

use work.pdts_defs.all;
use work.master_defs.all;

entity global is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic;
		rst: in std_logic;
		tx_err: in std_logic;
		part_sel: out std_logic_vector(calc_width(N_PART) - 1 downto 0);
		en: out std_logic;
		tstamp: out std_logic_vector(63 downto 0)
	);
		
end global;

architecture rtl of global is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal sel, ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ctrl_clr, ts_rst: std_logic;
	
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
      sel => ipbus_sel_global(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- Version

	ver: entity work.ipbus_roreg_v
		generic map(
			N_REG => 1,
			DATA => MASTER_VERSION
		)
		port map(
			ipb_in => ipbw(N_SLV_VERSION),
			ipb_out => ipbr(N_SLV_VERSION)
		);
		
-- Partition select

	part: entity work.ipbus_reg_v
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(N_SLV_PART_SEL),
			ipbus_out => ipbr(N_SLV_PART_SEL),
			q => sel
		);
		
	part_sel <= sel(0)(part_sel'range);

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

	stat(0) <= X"0000000" & "000" & tx_err;
	en <= ctrl(0)(0);
	ctrl_clr <= ctrl(0)(1);

-- Time stamp counter

	ts_rst <= ctrl_clr or rst;

	ts: entity work.ipbus_ctrs_v
		generic map(
			CTR_WDS => 2
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_TSTAMP),
			ipb_out => ipbr(N_SLV_TSTAMP),
			clk => clk,
			rst => ts_rst,
			inc(0) => '1',
			q => tstamp
		);
			
-- Spill counter

	ipbr(N_SLV_SPILL_CTR) <= IPB_RBUS_NULL;

end rtl;
