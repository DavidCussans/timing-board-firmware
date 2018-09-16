-- pdts_adjust
--
-- Phase adjustment block (sets delays and controls fine phase adjustment via external PLL)
--
-- Dave Newbold, Septemeber 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.pdts_defs.all;

entity pdts_adjust is
	port(
		sclk: in std_logic; -- Free-running system clock
		srst: in std_logic; -- System reset (sclk domain)
		d: in std_logic_vector(15 downto 0);
		fdel: out std_logic_vector(3 downto 0);
		cdel: out std_logic_vector(5 downto 0);
		adj_req: out std_logic;
		adj_ack: in std_logic;
		tx_en: out std_logic
	);

end pdts_adjust;

architecture rtl of pdts_adjust is

begin

	fdel <= (others => '0');
	cdel <= (others => '0');
	adj_req <= '0';
	tx_en <= '0';

end rtl;
