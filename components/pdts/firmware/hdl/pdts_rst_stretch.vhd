-- pdts_rst_stretch
--
-- Reset pulse stretcher for Xilinx FIFOs
--
-- See FIFO generator user guide for detail
-- Basically, need long reset pulse, no repeat for a few cycles, no we during reset
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity pdts_rst_stretch is
	port(
		clk: in std_logic;
		rst: in std_logic;
		rsto: out std_logic;
		wen: out std_logic
	);

end pdts_rst_stretch;

architecture rtl of pdts_rst_stretch is

	signal rst_ctr: unsigned(3 downto 0);
	signal rsti: std_logic;


begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				rst_ctr <= "0000";
			elsif rsti = '1' then
				rst_ctr <= rst_ctr + 1;
			end if;
		end if;
	end process;
	
	rsti <= '0' when rst_ctr = "1111" else '1';
	rsto <= rsti and rst_ctr(3) when rising_edge(clk); -- No glitches pls, used across clock domains
	wen <= not rsti when rising_edge(clk);

end rtl;
