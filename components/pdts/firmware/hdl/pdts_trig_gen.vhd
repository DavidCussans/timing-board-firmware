-- pdts_trig_gen
--
-- Generates time stamp packets
--
-- Dave Newbold, March 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.pdts_defs.all;

entity pdts_trig_gen is
	port(
		clk: in std_logic;
		rst: in std_logic;
		trig: in std_logic;
		d: out std_logic_vector(7 downto 0);
		v: out std_logic;
		last: out std_logic;
		ack: in std_logic;
		ren: in std_logic
	);

end pdts_trig_gen;

architecture rtl of pdts_trig_gen is

begin

	d <= X"01";
	v <= trig;
	last <= '1';

end rtl;
