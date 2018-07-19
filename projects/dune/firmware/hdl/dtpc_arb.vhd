-- dtpc_arb
--
-- Arbitrates between several incoming data streams
--
-- Dave Newbold, July 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.dtpc_stream_defs.all;

entity dtpc_arb is
	generic(
		N_PORTS: positive := 1
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		d: in dtpc_stream_w_array(N_PORTS - 1 downto 0);
		q: out dtpc_stream_r_array(N_PORTS - 1 downto 0);
		qa: out dtpc_stream_w;
		da: in dtpc_stream_r
	);

end dtpc_arb;

architecture rtl of dtpc_arb is

	signal ctr: unsigned(calc_width(N_PORTS) - 1 downto 0);
	signal sel: integer range N_PORTS - 1 downto 0 := 0;
	signal p: std_logic;

begin

	sel <= to_integer(ctr);

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				ctr <= 0;
				p <= '0';
			elsif p = '0' then
				if d(sel).h_valid = '1' then
					p <= '1'
				else
					ctr <= ctr + 1;
				end if;
			else
				if d(sel).h_valid = '1' and d(sel).c_valid = '1' and da.ack = '1' then
					p <= '0';
					ctr <= ctr + 1;
				end if;
			end if;
		end if;
	end process;

	gen: for i in range N_PORTS - 1 downto 0 generate
		q(i).ack <= da.ack when sel = i else '0';
	end generate;
	
	qa <= d(sel);

end rtl;
