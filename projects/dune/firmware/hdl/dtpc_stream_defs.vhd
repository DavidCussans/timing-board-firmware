-- dtpc_stream_defs
--
-- Basic data bus types for DUNE test firmware
--
-- Dave Newbold, July 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package dtpc_stream_defs is

	constant DTPC_STREAM_D_W: positive := 12; -- Data word width

	type dtpc_stream_w is
		record
			d: std_logic_vector(DTPC_STREAM_D_W - 1 downto 0);
			h_valid: std_logic;
			c_valid: std_logic;
		end record;
		
	type dtpc_stream_w_array is array(natural range <>) of dtpc_stream_w;
	constant DTPC_STREAM_W_NULL: dtpc_stream_w := ((others => '0'), '0', '0');
	
	type dtpc_stream_r is
		record
			ack: std_logic;
		end record;
		
	type dtpc_stream_r_array is array(natural range <>) of dtpc_stream_r;
	constant DTPC_STREAM_R_NULL: dtpc_stream_r := (ack => '0');

end dtpc_stream_defs;
