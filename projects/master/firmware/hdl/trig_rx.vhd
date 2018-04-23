-- trig_rx
--
-- Receiver for trigger command input
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_trig_rx.all;

use work.pdts_defs.all;

entity trig_rx is
	port(
		ipb_clk: in std_logic; -- IPbus connection
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		mclk: in std_logic; -- The serial IO clock
		clk: in std_logic; -- The system clock
		d: in std_logic; -- Input from trigger
		scmd_out: out cmd_w;
		scmd_in: in cmd_r
	);

end trig_rx;

architecture rtl of trig_rx is

--	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
--	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	
begin

	ipb_out <= IPB_RBUS_NULL;
	scmd_out <= CMD_W_NULL;

end rtl;
