-- pdts_prio_enc
--
-- Priority encoder
--
-- Dave Newbold, January 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus_reg_types.all;

entity pdts_prio_enc is
	generic(
		WIDTH: positive := 1
	);
	port(
		d: in std_logic_vector(WIDTH - 1 downto 0);
		sel: out std_logic_vector(calc_width(WIDTH) - 1 downto 0)
	);

end pdts_prio_enc;

architecture rtl of pdts_prio_enc is

begin

	process(d)
	begin
		for i in d'range loop
			sel <= (others => '0');
			if d(i) = '1' then
				sel <= std_logic_vector(to_unsigned(i, 4));
			end if;
		end loop;
	end process;

end rtl;
