-- spill_gate
--
-- Generates spill gate signal
--
-- cyc_len and spill_len are in units of 1 / (50MHz / 2^24) = 0.34s
--
-- Dave Newbold, June 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.pdts_defs.all;

entity spill_gate is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;		
		clk: in std_logic;
		rst: in std_logic;
		spill: out std_logic;
		scmd_out: out cmd_w;
		scmd_in: in cmd_r
	);

end spill_gate;

architecture rtl of spill_gate is

	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ectr: unsigned(23 downto 0) := (others => '0');
	signal cctr: unsigned(7 downto 0) := (others => '0');
	signal sctr: unsigned(15 downto 0);
	signal s, spill_i, ctrl_en, ctrl_en_fake: std_logic;
	signal ctrl_fake_cyc_len, ctrl_fake_spill_len: std_logic_vector(7 downto 0);

begin

-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			d => stat,
			q => ctrl
		);
		
	stat(0) <= std_logic_vector(sctr) & X"000" & "000" & spill_i;
	ctrl_en <= ctrl(0)(0);
	ctrl_en_fake <= ctrl(0)(1);
	ctrl_fake_cyc_len <= ctrl(0)(23 downto 16);
	ctrl_fake_spill_len <= ctrl(0)(31 downto 24);

-- Fake generator

	process(clk)
	begin
		if rising_edge(clk) then
			ectr <= ectr + 1;
			s <= '0';
			if rst = '1' or ctrl_en_fake = '0' then
				spill_i <= '0';
				sctr <= (others => '0');
				cctr <= (others => '0');
			elsif and_reduce(std_logic_vector(ectr)) = '1' then
				if cctr = unsigned(ctrl_fake_cyc_len) then
					cctr <= (others => '0');
					spill_i <= '1';
					s <= '1';
					sctr <= sctr + 1;
				else
					cctr <= cctr + 1;
					if cctr = unsigned(ctrl_fake_spill_len) then
						spill_i <= '0';
						s <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;
	
	spill <= spill_i;

	process(s, spill_i)
	begin
		if s = '1' then
			if spill_i = '1' then
				scmd_out.d <= X"0" & SCMD_SPILL_START;
			else
				scmd_out.d <= X"0" & SCMD_SPILL_STOP;
			end if;
			scmd_out.valid <= '1';
			scmd_out.last <= '1';
		else
			scmd_out <= CMD_W_NULL;
		end if;
	end process;

end rtl;
