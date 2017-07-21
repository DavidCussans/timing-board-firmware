-- pdts_tstamp_source
--
-- Generates spill gate signal
--
-- cyc_len and spill_len are in units of 1 / (50MHz / 2^24) = 0.34s
--
-- Dave Newbold, June 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.pdts_defs.all;

entity pdts_tstamp_source is
	generic(
		N_PART: positive
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;		
		clk: in std_logic;
		rst: in std_logic;
		tstamp: out std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		psync: out std_logic_vector(N_PART - 1 downto 0)
	);

end pdts_tstamp_source;

architecture rtl of pdts_tstamp_source is

	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);

begin

-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			d => stat,
			q => ctrl
		);
		
	stat(0) <= (others => '0');
	
	tstamp <= (others => '0');
	psync <= (others => '0');

end rtl;
