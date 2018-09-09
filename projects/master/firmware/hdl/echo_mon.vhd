-- echo_mon
--
-- Send and receive echo commands
--
-- Dave Newbold, February 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;

use work.pdts_defs.all;

entity echo_mon is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic;
		rst: in std_logic;
		tstamp: in std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		scmd_out: out cmd_w;
		scmd_in: in cmd_r
	);

end echo_mon;

architecture rtl of echo_mon is

begin
	
	ipb_out <= IPB_RBUS_NULL;
	scmd_out <= CMD_W_NULL;

end rtl;
