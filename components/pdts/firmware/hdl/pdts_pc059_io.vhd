-- pdts_pc059_io
--
-- Various functions for talking to the FMC board chipset
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_pdts_fmc_io.all;

library unisim;
use unisim.VComponents.all;

entity pdts_pc059_io is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		soft_rst: out std_logic;
		nuke: out std_logic;
		rst: out std_logic;
		locked: in std_logic;
		clk_p: in std_logic; -- 50MHz master clock from PLL
		clk_n: in std_logic;
		clk: out std_logic;
		rstb_clk: out std_logic; -- reset for PLL
		clk_lolb: in std_logic; -- PLL LOL
		d_p: in std_logic_vector(7 downto 0); -- data from fanout SFPs
		d_n: in std_logic_vector(7 downto 0);
		d: out std_logic_vector(7 downto 0);
		q_p: out std_logic; -- output to fanout
		q_n: out std_logic;
		q: in std_logic;
		sfp_los: in std_logic_vector(7 downto 0); -- fanout SFP LOS
		d_cdr_p: in std_logic; -- data input from CDR
		d_cdr_n: in std_logic;
		d_cdr: out std_logic;
		clk_cdr_p: in std_logic; -- clock from CDR
		clk_cdr_n: in std_logic;
		clk_cdr: out std_logic;
		cdr_los: in std_logic; -- CDR LOS
		cdr_lol: in std_logic; -- CDR LOL
		inmux: out std_logic_vector(2 downto 0); -- mux control
		rstb_i2cmux: out std_logic; -- reset for mux
		d_hdmi_p: in std_logic; -- data from upstream HDMI
		d_hdmi_n: in std_logic;
		d_hdmi: out std_logic;
		q_hdmi_p: out std_logic; -- output to upstream HDMI
		q_hdmi_n: out std_logic;
		q_hdmi: in std_logic;
		d_usfp_p: in std_logic; -- input from upstream SFP
		d_usfp_n: in std_logic;		
		d_usfp: out std_logic;
		q_usfp_p: out std_logic; -- output to upstream SFP
		q_usfp_n: out std_logic;
		q_usfp: in std_logic;
		usfp_fault: in std_logic; -- upstream SFP fault
		usfp_los: in std_logic; -- upstream SFP LOS
		usfp_txdis: out std_logic; -- upstream SFP tx_dis
		usfp_sda: inout std_logic; -- upstream SFP I2C
		usfp_scl: out std_logic;
		ucdr_los: in std_logic; -- upstream CDR LOS
		ucdr_lol: in std_logic; -- upstream CDR LOL
		ledb: out std_logic_vector(2 downto 0); -- FMC LEDs
		scl: out std_logic; -- main I2C
		sda: inout std_logic;
		rstb_i2c: out std_logic; -- reset for I2C expanders
		gpio_p: out std_logic_vector(2 downto 0); -- GPIO
		gpio_n: out std_logic_vector(2 downto 0)
	);

end pdts_pc059_io;

architecture rtl of pdts_pc059_io is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ctrl_gpio: std_logic_vector(2 downto 0);
	signal clk_i, clk_u, clk_cdr_i, clk_cdr_u, d_cdr_i, d_hdmi_i, d_usfp_i, q_i, q_hdmi_i, q_usfp_i: std_logic;
	signal clkdiv: std_logic_vector(1 downto 0);
	signal sda_o, usfp_sda_o: std_logic;
	
  attribute IOB: string;
  attribute IOB of d_cdr, d_hdmi, d_usfp, q_i, q_hdmi_i, q_usfp_i: signal is "TRUE";

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
      sel => ipbus_sel_pdts_fmc_io(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
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
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl
		);
		
	stat(0) <= X"000" & "000" & locked & sfp_los & '0' & not clk_lolb & cdr_lol & cdr_los & ucdr_lol & ucdr_los & usfp_fault & usfp_los;
	
	soft_rst <= ctrl(0)(0);
	nuke <= ctrl(0)(1);
	rst <= ctrl(0)(2);
	rstb_clk <= not ctrl(0)(3);
	rstb_i2cmux <= not ctrl(0)(4);
	rstb_i2c <= not ctrl(0)(5);
	inmux <= ctrl(0)(10 downto 8);
	ctrl_gpio <= ctrl(0)(14 downto 12);
	ledb <= not ctrl(0)(18 downto 16);
	
	usfp_txdis <= '0';

-- Clocks
			
	ibufg_clk: IBUFGDS
		port map(
			i => clk_p,
			ib => clk_n,
			o => clk_u
		);
		
	bufg_in: BUFG
		port map(
			i => clk_u,
			o => clk_i
		);
		
	clk <= clk_i;
	
	ibufds_clk_cdr: IBUFDS
		port map(
			i => cdr_clk_p,
			ib => cdr_clk_n,
			o => cdr_clk_u
		);
		
	bufh_clk_cdr: BUFG
		port map(
			i => clk_cdr_u,
			o => clk_cdr_i
		);
		
	clk_cdr <= clk_cdr_i;

-- Data inputs

	d_g: for i in 7 downto 0 generate
	
		signal di: std_logic;
		attribute IOB: string;
		attribute IOB of di: signal is "TRUE";
		
	begin
	
		ibufds_d: IBUFDS
			port map(
				i => d_p(i),
				ib => d_n(i),
				o => di
			);
 	
		d(i) <= di when rising_edge(clk_i); -- SFP input data registered on rising edge of clk (selectable edge later)
		
	end generate;
	
	ibufds_cdr: IBUFDS
		port map(
			i => d_cdr_p,
			ib => d_cdr_n,
			o => d_cdr_i
		);
		
	d_cdr <= d_cdr_i when rising_edge(clk_cdr_i); -- CDR input data registered on rising edge of clk_cdr
	
	ibufds_hdmi: IBUFDS
		port map(
			i => d_hdmi_p,
			ib => d_hdmi_n,
			o => d_hdmi_i
		);
		
	d_hdmi <= d_hdmi_i when rising_edge(clk_i); -- HDMI input data registered on rising edge of clk
	
	ibufds_usfp: IBUFDS
		port map(
			i => d_usfp_p,
			ib => d_usfp_n,
			o => d_usfp_i
		);
		
	d_usfp <= d_usfp_i when rising_edge(clk_i); -- uSFP input data registered on rising edge of clk
	
-- Data outputs

	q_i <= q when rising_edge(clk_i); -- SFP output data registered on rising edge of clk

	obuf_q: OBUFDS
		port map(
			i => q_i,
			o => q_p,
			ob => q_n
		);

	q_hdmi_i <= q_hdmi when rising_edge(clk_i); -- HDMI output data registered on rising edge of clk

	obuf_q: OBUFDS
		port map(
			i => q_hdmi_i,
			o => q_hdmi_p,
			ob => q_hdmi_n
		);

	q_usfp_i <= q_usfp when rising_edge(clk_i); -- uSFP output data registered on rising edge of clk

	obuf_q: OBUFDS
		port map(
			i => q_usfp_i,
			o => q_usfp_p,
			ob => q_usfp_n
		);

-- GPIO outputs
		
	gpio_g: for i in 2 downto 0 generate
		
		obuf_g: OBUFDS
			port map(
				i => ctrl_gpio(i),
				o => gpio_p(i),
				ob => gpio_n(i)
			);
			
	end generate;

-- Frequency measurement

	div: entity work.freq_ctr_div
		generic map(
			N_CLK => 2
		)
		port map(
			clk(0) => clk_i,
			clk(1) => clk_cdr_i,
			clkdiv => clkdiv
		);

	ctr: entity work.freq_ctr
		generic map(
			N_CLK => 2
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_FREQ),
			ipb_out => ipbr(N_SLV_FREQ),
			clkdiv => clkdiv
		);	

-- I2C

	i2c_uid: entity work.ipbus_i2c_master
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_I2C),
			ipb_out => ipbr(N_SLV_I2C),
			scl => scl,
			sda_o => sda_o,
			sda_i => sda
		);
	
	sda <= '0' when sda_o = '0' else 'Z';
	
	i2c_sfp: entity work.ipbus_i2c_master
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_USFP_I2C),
			ipb_out => ipbr(N_SLV_USFP_I2C),
			scl => usfp_scl,
			sda_o => usfp_sda_o,
			sda_i => usfp_sda
		);
	
	usfp_sda <= '0' when usfp_sda_o = '0' else 'Z';
				
end rtl;
