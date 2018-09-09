-- acmd_master
--
-- Source of async commands
--
-- Dave Newbold, October 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;

use work.pdts_defs.all;

entity acmd_master is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic;
		rst: in std_logic;
		acmd_out: out cmd_w;
		acmd_in: in cmd_r
	);

end acmd_master;

architecture rtl of acmd_master is

begin

	ipb_out <= IPB_RBUS_NULL;

	idle: entity work.pdts_idle_gen
		port map(
			clk => clk,
			rst => rst,
			acmd_out => acmdw,
			acmd_in => acmdr
		);
	
end rtl;
