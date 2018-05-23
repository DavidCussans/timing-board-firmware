-- scmd_gen_chan
--
-- Generates random sync commands
--
-- div words indicates power of two to divide rate by, with 256 prescale
-- e.g. at 50MHz clock, div = 0 is 12.2kHz, div = 7 is 95.4Hz, div = 15 is 0.373Hz
--
-- Dave Newbold, March 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.pdts_defs.all;


entity scmd_gen_chan is
	generic(
		ID: natural
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic;
		rst: in std_logic;
		tstamp: in std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		rand: in std_logic_vector(31 downto 0);
		scmd_out: out cmd_w;
		scmd_in: in cmd_r;
		ack: out std_logic;
		rej: out std_logic
	);

end scmd_gen_chan;

architecture rtl of scmd_gen_chan is

	constant ID_V: std_logic_vector := std_logic_vector(to_unsigned(ID, 4));
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stb: std_logic;
	signal ctrl_en, ctrl_patt, ctrl_force: std_logic;
	signal ctrl_type: std_logic_vector(7 downto 0);
	signal ctrl_rate_div: std_logic_vector(3 downto 0);
	signal r_i: integer range 2 ** 4 - 1 downto 0 := 0;
	signal mask: std_logic_vector(15 downto 0);
	signal src: std_logic_vector(27 downto 0);
	signal v: std_logic;

begin

	csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 0
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			slv_clk => clk,
			q => ctrl,
			qmask(0) => X"003fff07",
			stb(0) => stb
		);

	ctrl_en <= ctrl(0)(0);
	ctrl_patt <= ctrl(0)(1);
	ctrl_force <= ctrl(0)(2);
	ctrl_type <= ctrl(0)(15 downto 8);
	ctrl_rate_div <= ctrl(0)(19 downto 16);
	r_i <= to_integer(unsigned(ctrl_rate_div));
	
	process(r_i)
	begin
		for i in mask'range loop
			if i > r_i then -- Yeah, this is wrong (should be 'i >= r_i') but it's fixed in SW for now
				mask(i) <= '0';
			else
				mask(i) <= '1';
			end if;
		end loop;
	end process;
	
	src <= tstamp(27 downto 0) when ctrl_patt = '0' else rand(27 downto 0);
	v <= '1' when (or_reduce(mask and src(27 downto 12)) = '0' and src(11 downto 8) = std_logic_vector(to_unsigned(ID, 4)) and src(7 downto 0) = X"80" and ctrl_en = '1') or
		(ctrl_force = '1' and stb = '1') else '0';
		
	scmd_out.d <= ctrl_type;
	scmd_out.req <= v;
	scmd_out.last <= '1';
	
	ack <= v and scmd_in.ack;
	rej <= v and not scmd_in.ack;
		
end rtl;
