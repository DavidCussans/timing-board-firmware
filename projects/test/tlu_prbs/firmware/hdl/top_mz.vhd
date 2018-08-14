-- Standalone endpoint top level design
--
-- Dave Newbold, 14/1/18

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

entity top is port(
		sysclk_p: in std_logic;
		sysclk_n: in std_logic;
		clk_in_p: in std_logic;
		clk_in_n: in std_logic;
		d_in_p: in std_logic;
		d_in_n: in std_logic;
		clk_out_p: out std_logic;
		clk_out_n: out std_logic;
		d_out_p: out std_logic;
		d_out_n: out std_logic;
		debug: out std_logic_vector(11 downto 0)
	);

end top;

architecture rtl of top is

	signal sysclk_u, sysclk, clk_u, clk, d_in, d, q: std_logic;
	signal clkout: std_logic;
	signal vio_rst_u, vio_init_u, vio_rst, vio_init: std_logic;
	signal cyc_ctr, err_ctr, cyc_ctr_r, err_ctr_r: std_logic_vector(47 downto 0);
	signal zflag, zflag_r: std_logic;
	
	attribute MARK_DEBUG: string;
	attribute MARK_DEBUG of cyc_ctr_r, err_ctr_r, zflag_r: signal is "TRUE";
	
	COMPONENT vio_0
		PORT (
			clk : IN STD_LOGIC;
			probe_out0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
			probe_out1 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
		);
	END COMPONENT;

begin

-- Clock and data in

	ibufg_sysclk: IBUFGDS
		port map(
			i => sysclk_p,
			ib => sysclk_n,
			o => sysclk_u
		);
		
	bufg_sysclk: BUFG
		port map(
			i => sysclk_u,
			o => sysclk
		);

	ibufg_clk: IBUFGDS
		port map(
			i => clk_in_p,
			ib => clk_in_n,
			o => clk_u
		);
	
	bufg_clk: BUFG
		port map(
			i => clk_u,
			o => clk
		);
		
	ibufds_d: IBUFDS
		port map(
			i => d_in_p,
			ib => d_in_n,
			o => d_in
		);
		
-- IOB registers

	d <= d_in when rising_edge(clk);
	q <= d when rising_edge(clk);
	
-- Clock and data out

	oddr_clk: ODDR
		port map(
			q => clkout,
			c => clk,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		);
		
	obuf_clk: OBUFDS
		port map(
			i => clkout,
			o => clk_out_p,
			ob => clk_out_n
		);
		
	obuf_d: OBUFDS
		port map(
			i => q,
			o => d_out_p,
			ob => d_out_n
		);
		
-- VIO control

	vio: vio_0
		port map(
	    clk => sysclk,
	    probe_out0(0) => vio_rst_u,
	    probe_out1(0) => vio_init_u
	   );
	   
	synchro: entity work.pdts_synchro
		generic map(
			N => 2
		)
		port map(
			clk => sysclk,
			clks => clk,
			d(0) => vio_rst_u,
			d(1) => vio_init_u,
			q(0) => vio_rst,
			q(1) => vio_init
		);
	
-- PRBS check

	prbs_chk: entity work.prbs7_chk
		port map(
			clk => clk,
			rst => vio_rst,
			init => vio_init,
			d => d,
			err_ctr => err_ctr,
			cyc_ctr => cyc_ctr,
			zflag => zflag
		);	

	process(sysclk)
	begin
		if rising_edge(sysclk) then
			cyc_ctr_r <= cyc_ctr; -- SHonky as hell
			err_ctr_r <= err_ctr;
			zflag_r <= zflag;
		end if;
	end process;
		
-- Debug

	debug <= (others => '0');
		
end rtl;
