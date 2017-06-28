-- pdts_spill_gate
--
-- Generates spill gate signal
--
-- Dave Newbold, June 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.pdts_defs.all;
use work.master_defs.all;

entity pdts_spill_gate is
	generic(
		N_CHAN: positive := 1
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;		
		clk: in std_logic;
		rst: in std_logic;
		spill: out std_logic;
		scmd_out: cmd_w;
		scmd_in: cmd_r
	);

end pdts_spill_gate;

architecture rtl of pdts_spill_gate is

begin

	spill <= '0';

end rtl;
