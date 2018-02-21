-- ts_source
--
-- Maintains the timestamp counter
--
-- A simple resettable counter for now, might be more complex (e.g. time-of-day) later
--
-- Dave Newbold, June 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.pdts_defs.all;
use work.master_defs.all;

entity ts_source is
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
		tstamp: out std_logic_vector(8 * TSTAMP_WDS - 1 downto 0)
	);

end ts_source;

architecture rtl of ts_source is
	
begin

-- Timestamp counter

	ctr: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => 1,
			CTR_WDS => TSTAMP_WDS / 4
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			clk => clk,
			rst => rst,
			inc(0) => '1',
			q(8 * TSTAMP_WDS - 1 downto 0) => tstamp
		);
	
end rtl;
