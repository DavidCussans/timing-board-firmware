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
use work.pdts_defs.all;

entity pdts_scmd_merge is
	generic(
		N_SRC: positive := 1
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		stb: in std_logic;
		scmd_in_v: in cmd_w_array(N_SRC - 1 downto 0);
		scmd_out_v: out cmd_r_array(N_SRC - 1 downto 0);
		typ: out std_logic_vector(SCMD_W - 1 downto 0);
		tv: out std_logic;
		tgrp: in std_logic_vector(N_PART - 1 downto 0);
		scmd_out: out cmd_w;
		scmd_in: in cmd_r
	);

end pdts_scmd_merge;

architecture rtl of pdts_scmd_merge is

	signal valid: std_logic_vector(N_SRC - 1 downto 0);
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

	process(scmd_in)
	begin
		for i in N_SRC - 1 downto 0 loop
			valid(i) <= scmd_in_v(i).valid;
		end loop;
	end process;
	
	prio: entity work.pdts_prio_enc
		generic map(
			WIDTH => N_SRC
		)
		port map(
			d => valid,
			sel => p
		);

	ip <= to_integer(unsigned(p));
	ipa <= to_integer(unsigned(pa));
		
	go <= or_reduce(valid) and not active and scmd_in.ren;
		
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				active <= '0';
			elsif go = '1' then
				active <= '1';
				pa <= p;
				q <= tgrp & std_logic_vector(sctr);
				l <= '0';
			elsif active = '1' and stb = '1' then
				scmd_out.d <= scmd_in_v(ipa).d;
				scmd_out.last <= scmd_in_v(ipa).last;
				if last = '1' then
					active <= '0';
				end if;
			end if;
		end if;
	end process;
	
	scmd_out.valid <= active;
	typ <= scmd_in_v(ip).d(3 downto 0);
	tv <= go;
	ren <= stb;
	
	process(ip, go, stb)
	begin
		for i in N_SRC - 1 downto 0 loop
			if ip = i then
				scmd_out_v(i).ack <= go;
			else
				scmd_out_v(i).ack <= '0';
			end if;
			scmd_out_v(i).ren <= stb;
		end loop;
	end process;
	
end rtl;
