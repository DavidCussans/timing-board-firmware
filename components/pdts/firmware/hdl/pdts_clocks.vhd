-- pdts_clocks
--
-- Generates 50MHz system clock and data clock for PDTS master
--
-- Dave Newbold, October 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

entity pdts_clocks is
	port(
		clk_in_p: in std_logic; -- input clock from oscillator
 		clk_in_n: in std_logic;
		clk50: out std_logic; -- system clock
		clk_tx: out std_logic; -- serial IO clock
		locked: out std_logic; -- MMCM locked output
		rst_mmcm: in std_logic; -- MMCM reset 
		rsti: in std_logic; -- synchronous reset for distribution
		rst50: out std_logic -- clk50 domain reset
	);

end pdts_clocks;

architecture rtl of pdts_clocks is

	signal clk_in_ub, clk_in, clkfb: std_logic;
	signal clk_u, clk_i, clk_tx_u, clk_tx_i: std_logic;
	signal locked_i: std_logic;

begin

	ibufgds0: IBUFGDS port map(
		i => clk_in_p,
		ib => clk_in_n,
		o => clk_in_ub
	);

	bufg_clk_in: BUFG port map(
		i => clk_in_ub,
		o => clk_in
	);
	
	mmcm: MMCME2_BASE
		generic map(
			CLKIN1_PERIOD => 20.0,
			CLKFBOUT_MULT_F => 20.0,
			CLKOUT0_DIVIDE_F => 20.0, 
			CLKOUT1_DIVIDE => 20
		)
		port map(
			clkin1 => clk_in,
			clkfbin => clkfb,
			clkout0 => clk40_u,
			clkout1 => clk80_u,
			clkfbout => clkfb,
			locked => locked_i,
			rst => rst_mmcm,
			pwrdwn => '0'
		);

	locked <= locked_i;
	
	bufg: BUFG
		port map(
			i => clk_u,
			o => clk_i
		);
		
	clk50 <= clk_i;
	
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			rst50 <= rsti or not locked_i;
		end if;
	end process;
	
	bufg_tx: BUFG
		port map(
			i => clk_tx_u,
			o => clk_tx
		);
		
end rtl;
