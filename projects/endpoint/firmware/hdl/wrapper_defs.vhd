-- wrapper_defs
--
-- Constants and types for PDTS endpoint wrapper
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package wrapper_defs is

	constant WRAPPER_VERSION: std_logic_vector(31 downto 0) := X"00040008"; -- Version number
	
end wrapper_defs;
