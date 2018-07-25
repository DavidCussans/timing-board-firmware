-- net_addr
--
-- Temporary configuration of mac / ip
--
-- Dave Newbold, July 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package net_addr is

	constant MAC_ADDR: std_logic_vector(47 downto 0) := X"020ddba11643";
	constant IP_ADDR: std_logic_vector(31 downto 0) := X"c0a8c843";
	
end net_addr;
