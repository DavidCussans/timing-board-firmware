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
use work.master_defs.all;

entity pdts_scmd_merge is
	generic(
		N_SRC: positive := 1
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
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
	signal p: std_logic_vector(calc_width(N_SRC) - 1 downto 0);
	signal ip, ipa: integer range N_SRC - 1 downto 0 := 0;
	signal go, goq, last, active, src: std_logic;

begin

	process(scmd_in_v)
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
	ipa <= ip when go = '1' and rising_edge(clk);
		
	go <= or_reduce(valid) and not active;
	goq <= go and scmd_in.ack;
	last <= src and scmd_in_v(ipa).last and scmd_in.ren;

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				active <= '0';
				src <= '0';
			else
				active <= ((active and not last) or goq);
				if scmd_in.ren = '1' then
					src <= (src or (active or goq)) and not last;
				end if;
			end if;
		end if;
	end process;
	
	scmd_out.d <= (3 downto N_PART => '0') & tgrp & X"0" when src = '0' else scmd_in_v(ipa).d;
	scmd_out.valid <= go or active;
	scmd_out.last <= src and scmd_in_v(ipa).last;
	typ <= scmd_in_v(ip).d(3 downto 0);
	tv <= go;
	
	ogen: for i in N_SRC - 1 downto 0 generate
		scmd_out_v(i).ack <= goq when ip = i else '0';
		scmd_out_v(i).ren <= scmd_in.ren and src;
	end generate;
	
end rtl;
