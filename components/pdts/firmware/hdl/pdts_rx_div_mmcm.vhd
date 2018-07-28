-- pdts_rx_div_mmcm
--
-- Clock divider for rx side
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

library unisim;
use unisim.VComponents.all;

entity pdts_rx_div_mmcm is
	port(
		sclk: in std_logic;
		clk: out std_logic;
		phase_rst: in std_logic;
		phase_locked: out std_logic
	);
		
end pdts_rx_div_mmcm;

architecture rtl of pdts_rx_div_mmcm is

	signal clkfbout, clkfbin, clki: std_logic;
	
begin

	mmcm: MMCME2_BASE
		generic map(
			CLKIN1_PERIOD => (1000 / CLK_FREQ) / real(SCLK_RATIO), -- 250MHz input
			CLKFBOUT_MULT_F => (1000 / CLK_FREQ) / real(SCLK_RATIO), -- 1GHz VCO freq
			CLKOUT0_DIVIDE_F => 1000 / CLK_FREQ -- System clock output
		)
		port map(
			clkin1 => sclk,
			clkfbin => clkfbin,
			clkout0 => clki,
			clkfbout => clkfbout,
			locked => phase_locked,
			rst => phase_rst,
			pwrdwn => '0'
		);

	bufg0: BUFG
		port map(
			i => clki,
			o => clk
	);
	
	bufgfb: BUFG
		port map(
			i => clkfbout,
			o => clkfbin
	);

end rtl;
