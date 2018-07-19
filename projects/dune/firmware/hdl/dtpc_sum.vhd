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

begin

	q <= DTPC_STREAM_R_NULL;
	qa <= DTPC_STREAM_W_NULL;
	
end rtl;
