-- acmd_master
--
-- Source of async commands
--
-- Hardwired to produce endpoint control command only for now
--
-- Dave Newbold, October 2016	

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.pdts_defs.all;

entity acmd_master is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic;
		rst: in std_logic;
		acmd_out: out cmd_w;
		acmd_in: in cmd_r
	);

end acmd_master;

architecture rtl of acmd_master is

	signal ctrl, stat: ipb_reg_v(0 downto 0);
	signal go, go_d, pend, s: std_logic;
	signal c: unsigned(1 downto 0);
	signal s_i: integer range 1 downto 0 := 0;
	signal acmd_out_i: cmd_w_array(1 downto 0);
	signal acmd_in_i: cmd_r_array(1 downto 0);

begin


-- Idle generator

	idle: entity work.pdts_idle_gen
		port map(
			clk => clk,
			rst => rst,
			acmd_out => acmd_out_i(0),
			acmd_in => acmd_in_i(0)
		);
		
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
		
	stat(0) <= (others => '0');

-- Packet generator
	
	sync: entity work.pdts_synchro
		port map(
			clk => ipb_clk,
			clks => clk,
			d(0) => ctrl(0)(0),
			q(0) => go
		);
		
	go_d <= go when rising_edge(clk);
	pend <= (pend or (go and not go_d)) and not (acmd_in_i(1).ren or rst) when rising_edge(clk);
	
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or c = "10" then
				c <= "00";
			elsif acmd_in_i(1).ren = '1' then
				c <= c + 1;
			end if;
		end if;
	end process;
	
	with c select acmd_out_i(1).d <=
		ctrl(0)(15 downto 8) when "00",
		ctrl(0)(23 downto 16) when "01",
		ctrl(0)(31 downto 24) when others;
	
	acmd_out_i(1).last <= '1' when c = "10" else '0';
	acmd_out_i(1).req <= pend;
	
-- Arbitrator

	s_i <= 0 when s = '0' else 1;

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				s <= '0';
			elsif acmd_out_i(s_i).last = '1' and acmd_in.ren = '1' then
				s <= pend;
			end if;
		end if;
	end process;
	
	acmd_out.d <= acmd_out_i(s_i).d;
	acmd_out.last <= acmd_out_i(s_i).last;
	acmd_out.req <= acmd_out_i(s_i).req;

	acmd_in_i(0).ren <= acmd_in.ren when s = '0' else '0';
	acmd_in_i(1).ren <= acmd_in.ren when s = '1' else '0';
	
end rtl;
