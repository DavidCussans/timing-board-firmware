-- pdts_ts_gen
--
-- Generates time stamp packets
--
-- Dave Newbold, March 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.pdts_defs.all;

entity pdts_ts_gen is
	port(
		clk: in std_logic;
		rst: in std_logic;
		clr: in std_logic;
		trig: in std_logic;
		tstamp: out std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		evtctr: out std_logic_vector(8 * EVTCTR_WDS - 1 downto 0);
		div: in std_logic_vector(4 downto 0);		
		d: out std_logic_vector(7 downto 0);
		v: out std_logic;
		last: out std_logic;
		ack: in std_logic;
		ren: in std_logic
	);

end pdts_ts_gen;

architecture rtl of pdts_ts_gen is

	signal t: unsigned(8 * TSTAMP_WDS - 1 downto 0);
	signal ectr: unsigned(8 * EVTCTR_WDS - 1 downto 0);
	signal cap: std_logic_vector(8 * (TSTAMP_WDS + EVTCTR_WDS + 1) - 1 downto 0);
	signal ctr: unsigned(3 downto 0);
	signal sync, go, s, done: std_logic;

begin

-- Timestamp

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or clr = '1' then
				t <= (others => '0');
			else
				t <= t + 1;
			end if;
		end if;
	end process;

	tstamp <= std_logic_vector(t);
	
-- Event counter

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				ectr <= (others => '0');
			else
				if trig = '1' then
					ectr <= ectr + 1;
				end if;
			end if;
		end if;
	end process;
	
	evtctr <= std_logic_vector(ectr);
	
-- Sending packet

	sync <= not or_reduce(std_logic_vector(t(to_integer(unsigned(div)) + 3 downto 0)));
	go <= sync and ack;
	
-- Capture

	s <= ((s and not (done and ren)) or go) and not rst when rising_edge(clk);
	cap(8 * (TSTAMP_WDS + EVTCTR_WDS + 1) - 1 downto 8) <= evtctr & std_logic_vector(t) when go = '1' and rising_edge(clk);
	cap(7 downto 0) <= X"0F"; -- aux = 0x0, tcmd = 0xf
		
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				ctr <= X"0";
			elsif s = '1' and ren = '1' then
				if done = '1' then
					ctr <= X"0";
				else
					ctr <= ctr + 1;
				end if;
			end if;
		end if;
	end process;
	
	done <= '1' when ctr = TSTAMP_WDS + EVTCTR_WDS else '0';

-- Output

	d <= cap(8 * (to_integer(ctr) + 1) - 1 downto 8 * to_integer(ctr));
	v <= sync or s;
	last <= done;

end rtl;
