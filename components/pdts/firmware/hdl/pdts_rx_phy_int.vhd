-- pdts_rx_phy_int
--
-- The receive PHY, internal deserialiser / fixed clock phase version
--
-- Dave Newbold, March 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.pdts_defs.all;

entity pdts_rx_phy_int is
	port(
		clk: in std_logic;
		rst: in std_logic;
		rxd: in std_logic;
		rxclk: in std_logic;
		locked: out std_logic;
		err: out std_logic;
		q: out std_logic_vector(7 downto 0);
		k: out std_logic;
		stbo: out std_logic
	);

end pdts_rx_phy_int;

architecture rtl of pdts_rx_phy_int is

	signal w_io: std_logic;
	signal wa, wb, w, t: std_logic_vector(9 downto 0) := "0000000000";
	signal d: std_logic_vector(7 downto 0);
	signal c, ca, cb, rsta, rstb, g, ki, err_i: std_logic;
	signal sctr: unsigned(3 downto 0);
	
begin

-- SR

	w_io <= rxd when rising_edge(rxclk); -- IOB register
	wa <= w_io & wa(9 downto 1) when rising_edge(rxclk);
	
-- Comma det

	process(rxclk)
	begin
		if rising_edge(rxclk) then
			if wa = CCHAR_PD or wa = CCHAR_ND then
				c <= '1';
			else
			 	c <= '0';
			end if;
			ca <= c and not g;
			if ca = '1' then
				t <= "0000000001";
			else
				t <= t(0) & t(9 downto 1);
			end if;
			cb <= c and g and not t(2);
			rsta <= rst;
			rstb <= rsta;
			err_i <= (err_i or cb) and not rstb;
		end if;
	end process;
	
	err <= err_i;	

-- Capture

	wb <= wa when t(3) = '1' and rising_edge(rxclk);
	w <= wb when rising_edge(clk);
	
	dec: entity work.dec8b10b
		port map(
			clk => clk,
			rst => rst,
			en => '1',
			d => w,
			q => d,
			k => ki,
			cerr => open,
			derr => open
		);

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				g <= '0';
			elsif ki = '1' and d = CCHAR and g = '0' then
				g <= '1';
				sctr <= X"0";
			elsif sctr = (10 / SCLK_RATIO) - 1 then
				sctr <= X"0";
			else
				sctr <= sctr + 1;
			end if;
			k <= ki;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if ki = '1' then
				if d = CCHAR then
					q <= X"00";
				else
					q <= X"01";
				end if;
			else
				q <= d;
			end if;
		end if;
	end process;
	
	locked <= g;
	stbo <= '1' when sctr = X"0" else '0';

end rtl;
