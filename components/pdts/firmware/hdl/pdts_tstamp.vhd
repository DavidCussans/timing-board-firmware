-- pdts_tstamp
--
-- Maintains the timestamp and event counters
--
-- Dave Newbold, March 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

entity pdts_tstamp is
	port(
		clk: in std_logic;
		rst: in std_logic;
		d: in std_logic_vector(7 downto 0);
		s_valid: in std_logic;
		s_first: in std_logic;
		tstamp: out std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		evtctr: out std_logic_vector(8 * EVTCTR_WDS - 1 downto 0);
		rdy: out std_logic
	);

end pdts_tstamp;

architecture rtl of pdts_tstamp is

	signal sr: std_logic_vector(8 * (TSTAMP_WDS + EVTCTR_WDS) - 1 downto 0);
	signal tstamp_i: unsigned(8 * TSTAMP_WDS - 1 downto 0);
	signal evtctr_i: unsigned(8 * EVTCTR_WDS - 1 downto 0);
	signal ctr: unsigned(3 downto 0);
	signal lock, pkt_end, pkt_end_d: std_logic;

begin
		
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or pkt_end = '1' then
				ctr <= X"0";
				pkt_end <= '0';
			elsif s_valid = '1' and (ctr /= X"0" or (s_first = '1' and d(3 downto 0) = X"F")) then
				ctr <= ctr + 1;
				sr <= d & sr(8 * (TSTAMP_WDS + EVTCTR_WDS) - 1 downto 8);
				if ctr = TSTAMP_WDS + EVTCTR_WDS then
					pkt_end <= '1';
				end if;
			end if;
			pkt_end_d <= pkt_end;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				tstamp_i <= (others => '0');
				evtctr_i <= (others => '0');
				lock <= '0';
			else
				if pkt_end = '1' then
					evtctr_i <= unsigned(sr(8 * (TSTAMP_WDS + EVTCTR_WDS) - 1 downto 8 * TSTAMP_WDS));
				elsif s_valid = '1' and EVTCTR_MASK(to_integer(unsigned(d(3 downto 0)))) = '1' then
					evtctr_i <= evtctr_i + 1;
				end if;
				if lock = '0' then
					if pkt_end = '1' then
						tstamp_i <= unsigned(sr(8 * TSTAMP_WDS - 1 downto 0));
						lock <= '1';
					end if;
				else
					tstamp_i <= tstamp_i + 1;
					if pkt_end_d = '1' and tstamp_i /= unsigned(sr(8 * TSTAMP_WDS - 1 downto 0))   then
						lock <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;
	
	tstamp <= std_logic_vector(tstamp_i);
	evtctr <= std_logic_vector(evtctr_i);
	rdy <= lock;

end rtl;
