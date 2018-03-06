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
		tx_err: in std_logic
	);
		
end global;

architecture rtl of global is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl, stat: ipb_reg_v(0 downto 0);
	
	constant MASTER_CONF: std_logic_vector(31 downto 0) := X"000000" & std_logic_vector(to_unsigned(N_CHAN, 4)) & std_logic_vector(to_unsigned(N_PART, 4));
	
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

-- Config

	config: entity work.ipbus_roreg_v
		generic map(
			N_REG => 1,
			DATA => MASTER_CONF
		)
		port map(
			ipb_in => ipbw(N_SLV_CONFIG),
			ipb_out => ipbr(N_SLV_CONFIG)
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

	stat(0) <= X"0000000" & "000" & tx_err;

end rtl;
