-- pdts_scmd_merge
--
-- Merge sync cmd streams from multiple sources, and send to tx block
--
-- Dave Newbold, March 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus_reg_types.all;

entity pdts_scmd_merge is
	generic(
		N_SRC: positive := 1
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		stb: in std_logic;
		rdy: in std_logic;
		d: in std_logic_vector(8 * N_SRC - 1 downto 0);
		dv: in std_logic_vector(N_SRC - 1 downto 0);
		last: in std_logic_vector(N_SRC - 1 downto 0);
		ack: out std_logic_vector(N_SRC - 1 downto 0);
		ren: out std_logic;
		typ: out std_logic_vector(3 downto 0);
		tv: out std_logic;
		grp: in std_logic_vector(3 downto 0);
		q: out std_logic_vector(7 downto 0);
		v: out std_logic
	);

end pdts_scmd_merge;

architecture rtl of pdts_scmd_merge is

	signal p, pa: std_logic_vector(calc_width(N_SRC) - 1 downto 0);
	signal sctr: unsigned(3 downto 0);
	signal ip, ipa: integer range N_SRC - 1 downto 0 := 0;
	signal go, active, l: std_logic;

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if stb = '1' then
				sctr <= (others => '0');
			else
				sctr <= sctr + 1;
			end if;
		end if;
	end process;

	prio: entity work.pdts_prio_enc
		generic map(
			WIDTH => N_SRC
		)
		port map(
			d => dv,
			sel => p
		);

	ip <= to_integer(unsigned(p));
	ipa <= to_integer(unsigned(pa));
		
	go <= or_reduce(dv) and not active and rdy;
		
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				active <= '0';
			elsif go = '1' then
				active <= '1';
				pa <= p;
				q <= grp & std_logic_vector(sctr);
				l <= '0';
			elsif active = '1' and stb = '1' then
				q <= d(8 * (ipa + 1) - 1 downto 8 * ipa);
				l <= last(ipa);
				if l = '1' then
					active <= '0';
				end if;
			end if;
		end if;
	end process;
	
	v <= active;
	typ <= d(8 * (ip + 1) - 5 downto 8 * ip);
	tv <= go;
	ren <= stb;
	
	process(pa, go)
	begin
		for i in N_SRC - 1 downto 0 loop
			if ip = i then
				ack(i) <= go;
			else
				ack(i) <= '0';
			end if;
		end loop;
	end process;
	
end rtl;
