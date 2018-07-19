-- dtpc_wbuf
--
-- Data source buffer
--
-- Dave Newbold, July 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_decode_dtpc_src.all;
use work.dtpc_stream_defs.all;

entity dtpc_wbuf is
	generic(
		N_MUX: positive := 1;
		BLOCK_RADIX: positive := 8
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic;
		rst: in std_logic;
		q: out dtpc_stream_w;
		d: in dtpc_stream_r;
		go: in std_logic;
		done: out std_logic
	);

end dtpc_wbuf;

architecture rtl of dtpc_wbuf is

begin

	ipb_out <= IPB_RBUS_NULL;
	q <= DTPC_STREAM_W_NULL;
	done <= '0';

end rtl;
