-- pdts_rx_div_sim
--
-- Simulation of PLL / DLL clock divider
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.pdts_defs.all;

entity pdts_rx_div_sim is
	port(
		sclk_i: in std_logic;
		sclk_o: out std_logic;
		clk: out std_logic;
		phase_rst: in std_logic;
		phase_locked: out std_logic
	);

end pdts_rx_div_sim;

architecture tb of pdts_rx_div_sim is

	signal sclk_d, lock: std_logic;
	signal clki: std_logic := '1';
	signal ctr: unsigned(3 downto 0) := X"0";
	
begin

	sclk_d <= sclk_i;
	sclk_o <= sclk_d; -- Align delta delays between sclk_o and clk
	
	process(sclk_i)
	begin
		if sclk_i'event then
			if phase_rst = '1' then
				ctr <= X"0";
				clki <= sclk_i;
				if rising_edge(sclk_i) then
					lock <= '0';
				end if;
			else
				if rising_edge(sclk_i) then
					lock <= '1';
				end if;
				if ctr = SCLK_RATIO - 1 then
					ctr <= X"0";
					clki <= not clki;
				else
					ctr <= ctr + 1;
				end if;
			end if;
		end if;
	end process;

	clk <= clki;
	
-- Fake the random response behaviour of an MMCM
	
	process(lock)
		variable seed1, seed2: integer := 123456789;
		variable rand: real;
	begin
		if lock = '0' then
			phase_locked <= '0';
		else
			uniform(seed1, seed2, rand);
			phase_locked <= '1' after rand * 1 us;
		end if;
	end process;

end tb;
