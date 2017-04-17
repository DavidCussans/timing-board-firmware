-- master_clk
--
-- Clock divider and sync gen for master
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

entity master is
	port(
		mclk: in std_logic;
		locked: out std_logic;
		clk: out std_logic;
		stb: out std_logic
	);
		
end master;

architecture rtl of master is

	signal clki: std_logic;
	signal sctr: unsigned(3 downto 0) := X"0";

begin
		
-- Clock divider

	clkgen: entity work.pdts_rx_div_mmcm
		port map(
			sclk => mclk,
			clk => clk,
			phase_rst => '0',
			phase_locked => locked
		);
		
	clk <= clki;

-- Strobe gen

	process(clki)
	begin
		if rising_edge(clki) then
			if sctr = (10 / SCLK_RATIO) - 1 then
				sctr <= X"0";
			else
				sctr <= sctr + 1;
			end if;
		end if;
	end process;
	
	stb <= '1' when sctr = 0 else '0';

end rtl;
