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

	signal c: unsigned(3 downto 0);
	signal done: std_logic;

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				c <= "0000";
				q <= (others => '0');
			elsif a_valid = '1' then
				if a_first = '1' then
					c <= "0001";
					q(15 downto 8) <= a_d;
				else
					c <= c + 1;
					if c = "0001" then
						q(7 downto 0) <= a_d;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	done <= '1' when c = "0001" else '0';

	s <= done and a_valid when rising_edge(clk);
	
end rtl;
