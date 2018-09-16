-- pdts_acmd_rx
--
-- Receive async commands (only one type for now, can expand later)
--
-- Dave Newbold, October 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

entity pdts_acmd_rx is
	port(
		clk: in std_logic;
		rst: in std_logic;
		a_d: in std_logic_vector(7 downto 0);
		a_valid: in std_logic;
		a_last: in std_logic;
		q: out std_logic_vector(15 downto 0);
		s: out std_logic
	);

end pdts_acmd_rx;

architecture rtl of pdts_acmd_rx is

	signal c: std_logic;
	signal qi: std_logic_vector(7 downto 0);

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				c <= '0';
				q <= (others => '0');
			elsif a_valid = '1' then
				c <= not c;
				if c = '0' then
					qi <= a_d;
				else
					q <= a_d & qi
				end if;
			end if;
		end if;
	end process;

	s <= a_valid and c when rising_edge(clk);
	
end rtl;
