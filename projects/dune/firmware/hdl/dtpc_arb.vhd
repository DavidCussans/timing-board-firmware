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

begin

	q <= (others => DTPC_STREAM_R_NULL);
	qa <= DTPC_STREAM_W_NULL;

end rtl;
