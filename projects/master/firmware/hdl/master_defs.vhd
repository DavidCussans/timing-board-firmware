-- master_defs
--
-- Constants and types for PDTS master
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package master_defs is

	constant MASTER_VERSION: std_logic_vector(31 downto 0) := X"00000304"; -- Version number
	constant N_PART: integer := 1; -- Number of partitions (max 4 at present)
	constant N_CHAN: integer := 1; -- Number of scmd generator channels
	constant N_FIFO: integer := 1;
	constant TS_DIV: unsigned(27 downto 0) := X"3200000"; -- Once per 1024 * 1024 * 2 cycles of 2MHz clock = 1.05s
	
end master_defs;
