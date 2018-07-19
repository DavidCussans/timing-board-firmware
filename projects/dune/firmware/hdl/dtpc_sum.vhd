-- dtpc_sum
--
-- Trivial example design to add up total content of a whole block
--
-- Dave Newbold, July 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.dtpc_stream_defs.all;

entity dtpc_sum is
	port(
		clk: in std_logic;
		rst: in std_logic;
		d: in dtpc_stream_w;
		q: out dtpc_stream_r;
		qa: out dtpc_stream_w;
		da: in dtpc_stream_r
	);

end dtpc_sum;

architecture rtl of dtpc_sum is

	signal ictr, octr: unsigned(1 downto 0);
	signal s: unsigned(2 * DTPC_STREAM_D_W - 1 downto 0);
	signal chan, tsl, tsh: std_logic_vector(DTPC_STREAM_D_W - 1 downto 0);
	signal last, pend: std_logic;

begin

	q.ack <= not pend;
	
	last <= d.h_valid and d.c_valid;
	last_d <= last when rising_edge(clk);
	
-- Grab header
	
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or last = '1' then
				ictr <= 0;
			elsif d.h_valid = '1' then
				ictr <= ictr + 1;
				if ictr = 0 then
					chan <= d.d;
				elsif ictr = 1 then
					tsl <= d.d;
				else
					tsh <= d.d
				end if;
			end if;
		end if;
	end process;
	
-- Summation
	
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or last_d = '1' then
				s <= (others => '0');
			elsif d.c_valid = '1' then
				s <= s + unsigned(d.d);
			end if;
		end if;
	end process;
	
-- Output

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				pend <= '0';
			elsif last_d = '1' then
				pend <= '1';
				octr <= 0;
			else
				if da.ack = '1' then
					if octr /= 3 then
						octr <= octr + 1;
					else
						pend <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;
	
-- Output data
				
	with octr select q.d <=
		chan when 0,
		tsl when 1,
		tsh when 2,
		std_logic_vector(s) when others;

end rtl;
