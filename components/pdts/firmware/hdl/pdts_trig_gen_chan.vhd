-- pdts_trig_gen_chan
--
-- Generates random sync commands
--
-- Dave Newbold, March 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

entity pdts_trig_gen_chan is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic;
		rst: in std_logic;
		rand: in std_logic_vector(31 downto 0);
		d: out std_logic_vector(7 downto 0);
		v: out std_logic;
		last: out std_logic;
		ack: in std_logic;
		ren: in std_logic
	);

end pdts_trig_gen_chan;

architecture rtl of pdts_trig_gen_chan is

	signal ctrl: ipb_reg_v(0 downto 0);

begin

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 0
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			q => ctrl
		);

	d <= X"01";
	v <= trig;
	last <= '1';

end rtl;
