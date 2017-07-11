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
	constant TS_RATE_RADIX: positive := 26; -- Issue TS at a rate of 50MHz/(2^26) = 0.75Hz per partition. Never set to less than 15.
	constant SAMP_SYNC_DIV: positive := 16#3200000; -- Sample sync on 2MHz edges, about once per second
	
end master_defs;
