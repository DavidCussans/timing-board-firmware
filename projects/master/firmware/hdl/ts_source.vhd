-- ts_source
--
-- Generates timestamp
--
-- Dave Newbold, June 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.pdts_defs.all;
use work.master_defs.all;

entity ts_source is
	generic(
		N_PART: positive
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;		
		clk: in std_logic;
		rst: in std_logic;
		tstamp: out std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		psync: out std_logic_vector(N_PART - 1 downto 0)
	);

end ts_source;

architecture rtl of ts_source is

	signal tctr: unsigned(calc_width(TS_DIV) - 1 downto 0);
	signal pctr: unsigned(3 downto 0);
	
begin

-- Timestamp counter

	ctr: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => 1,
			CTR_WDS => TSTAMP_WDS / 4
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			clk => clk,
			rst => rst,
			inc(0) => '1',
			q(8 * TSTAMP_WDS - 1 downto 0) => tstamp
		);
		
-- Sync counter
		
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				tctr <= (others => '0');
				pctr <= (others => '0');
			else
				tctr <= tctr + 1;
				if tctr = TS_DIV then
					pctr <= pctr + 1;
				end if;
			end if;
		end if;
	end process;
	
	process(pctr)
	begin
		for i in N_PART - 1 downto 0 loop
			if pctr = i and or_reduce(std_logic_vector(tctr)) = '0' then
				psync(i) <= '1';
			else
				psync(i) <= '0';
			end if;
		end loop;
	end process;
	
end rtl;
