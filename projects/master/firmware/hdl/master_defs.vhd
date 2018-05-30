-- master_defs
--
-- Constants and types for PDTS master
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package master_defs is

	constant MASTER_VERSION: std_logic_vector(31 downto 0) := X"00040008"; -- Version number
	constant N_PART: integer := 4; -- Number of partitions (max 4 at present)
	constant N_CHAN: integer := 4; -- Number of scmd generator channels
	constant TS_DIV: positive := 50000000; -- 1Hz (must be divisible by 25)
	
end master_defs;
