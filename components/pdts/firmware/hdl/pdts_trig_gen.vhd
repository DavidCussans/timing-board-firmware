-- pdts_trig_gen
--
-- Generates random sync commands
--
-- Dave Newbold, March 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_pdts_trig_gen.all;

entity pdts_trig_gen is
	generic(
		N_CHAN: positive := 1
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;		
		clk: in std_logic;
		rst: in std_logic;
		trig: out std_logic;
		d: out std_logic_vector(7 downto 0);
		v: out std_logic;
		last: out std_logic;
		ack: in std_logic;
		ren: in std_logic
	);

end pdts_trig_gen;

architecture rtl of pdts_trig_gen is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal rand: std_logic_vector(31 downto 0);
	type d_g_t is array(N_CHAN - 1 downto 0) of std_logic_vector(7 downto 0);
	signal d_g: d_g_t;
	signal v_g, last_g, ack_g: std_logic_vector(N_CHAN - 1 downto 0);
	signal inc: std_logic_vector(N_CHAN * 2 - 1 downto 0);
	signal s: std_logic_vector(calc_width(N_CHAN) - 1 downto 0);
	signal si: integer range N_CHAN - 1 downto 0 := 0;

begin

-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
		generic map(
			NSLV => N_SLAVES,
			SEL_WIDTH => IPBUS_SEL_WIDTH
		)
		port map(
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			sel => ipbus_sel_pdts_trig_gen(ipb_in.ipb_addr),
			ipb_to_slaves => ipbw,
			ipb_from_slaves => ipbr
		);
		
-- Channel select register

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 0
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(N_SLV_CHAN_SEL),
			ipbus_out => ipbr(N_SLV_CHAN_SEL),
			q => ctrl
		);
		
-- RNG

	rng: entity work.rng_wrapper
		port map(
			clk => clk,
			rst => rst,
			random => rand
		);

-- Channels
		
	tgen: for i in N_CHAN - 1 downto 0 generate
	
		signal ack_g: std_logic;
	
	begin
	
		ack_g <= ack when si = i else '0';
	
		gen: entity work.pdts_trig_gen_chan
			port map(
				ipb_clk => ipb_clk,
				ipb_rst => ipb_rst,
				ipb_in => ipbw(N_SLV_CTRL),
				ipb_out => ipbr(N_SLV_CTRL),
				clk => clk,
				rst => rst,
				rand => rand,
				d => d_g(i),
				v => v_g(i),
				last => last_g(i),
				ack => ack_g,
				ren => ren
			);
			
		inc(2 * i) <= v_g(i)
		inc(2 * i + 1) <= v_g(i) and ack_g;

	end generate;
  
-- Counters

	cnt: entity work.ipbus_ctrs_ported
		generic map(
			N_CTRS => N_CHAN * 2
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CTRS),
			ipb_out => ipbr(N_SLV_CTRS),
			slv_clk => clk,
			slv_rst => rst,
			inc => inc
		);
		
-- Output

	prio: entity work.pdts_prio_enc
		generic map(
			WIDTH => N_CHAN
		)
		port map(
			d => v_g,
			sel => s
		);
		
	si <= to_integer(unsigned(s));
	
	d <= d_g(si);
	v <= v_g(si);
	last <= last_g(si);

-- Trigger output

	trig <= '0';
	
end rtl;
