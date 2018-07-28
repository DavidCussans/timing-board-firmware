-- pdts_rx_mul_mmcm
--
-- Clock mutliplier for tlu
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

library unisim;
use unisim.VComponents.all;

entity pdts_rx_mul_mmcm is
	port(
		clk: in std_logic;
		sclk: out std_logic;
		phase_rst: in std_logic;
		phase_locked: out std_logic
	);
		
end pdts_rx_mul_mmcm;

architecture rtl of pdts_rx_mul_mmcm is

	signal clkfbout, clkfbin, sclki: std_logic;
	
begin

	mmcm: MMCME2_BASE
		generic map(
			CLKIN1_PERIOD => 1000 / CLK_FREQ, -- 50MHz input
			CLKFBOUT_MULT_F => 1000 / CLK_FREQ, -- 1GHz VCO freq
			CLKOUT0_DIVIDE_F => (1000 / CLK_FREQ) / real(SCLK_RATIO) -- IO clock output
		)
		port map(
			clkin1 => clk,
			clkfbin => clkfbin,
			clkout0 => sclki,
			clkfbout => clkfbout,
			locked => phase_locked,
			rst => phase_rst,
			pwrdwn => '0'
		);

	bufg0: BUFG
		port map(
			i => sclki,
			o => sclk
	);
	
	bufgfb: BUFG
		port map(
			i => clkfbout,
			o => clkfbin
	);

end rtl;
