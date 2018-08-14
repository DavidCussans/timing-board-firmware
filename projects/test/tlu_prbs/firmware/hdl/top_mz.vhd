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

	signal sysclk_u, sysclk, clk_u, clk, d_in, d, dd, d_del, q: std_logic;
	signal clkout: std_logic;
	signal vio_rst_u, vio_init_u, vio_edge_u, vio_rst, vio_init, vio_edge, vio_inc: std_logic;
	signal inc, vio_inc_d: std_logic;
	signal cyc_ctr, err_ctr, cyc_ctr_r, err_ctr_r: std_logic_vector(47 downto 0);
	signal zflag, zflag_r: std_logic;
	signal cntout: std_logic_vector(4 downto 0);
	
	attribute MARK_DEBUG: string;
	attribute MARK_DEBUG of cyc_ctr_r, err_ctr_r, zflag_r, cntout: signal is "TRUE";
	
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

	idel: IDELAYE2
		generic map(
			IDELAY_TYPE => "VARIABLE"
		)
		port map(
			c => sysclk,
			regrst => '0',
			ld => vio_rst,
			ce => inc,
			inc => '1',
			cinvctrl => '0',
			cntvaluein => "00000",
			idatain => d_in,
			datain => '0',
			ldpipeen => '0',
			dataout => d_del,
			cntvalueout => cntout
		);
		
	vio_inc_d <= vio_inc when rising_edge(sysclk);
	inc <= vio_inc and not vio_inc_d;

	iddr: IDDR
		generic map(
			DDR_CLK_EDGE => "SAME_EDGE"
		)
		port map(
			q1 => d_in_r,
			q2 => d_in_f,
			c => clk,
			ce => '1',
			d => d_del,
			r => '0',
			s => '0'
		);
		
	d <= d_in_r when vio_edge = '0' else d_in_f;
	dd <= d when rising_edge(clk);
	q <= dd when rising_edge(clk);
	
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
	    probe_out1(0) => vio_init_u,
	    probe_out2(0) => vio_edge_u,
	    probe_out3(0) => vio_inc    
	   );
	   
	synchro: entity work.pdts_synchro
		generic map(
			N => 3
		)
		port map(
			clk => sysclk,
			clks => clk,
			d(0) => vio_rst_u,
			d(1) => vio_init_u,
			d(2) => vio_edge_u,
			q(0) => vio_rst,
			q(1) => vio_init,
			q(2) => vio_edge
		);
	
-- PRBS check

	prbs_chk: entity work.prbs7_chk
		port map(
			clk => clk,
			rst => vio_rst,
			init => vio_init,
			d => dd,
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
