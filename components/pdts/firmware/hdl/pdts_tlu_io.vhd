-- pdts_pc059_io
--
-- Various functions for talking to the pc059 board chipset
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_pdts_pc059_io.all;

library unisim;
use unisim.VComponents.all;

entity pdts_pc059_io is
	generic(
		CARRIER_TYPE: std_logic_vector(7 downto 0);
		DESIGN_TYPE: std_logic_vector(7 downto 0)
	);
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

	constant BOARD_TYPE: std_logic_vector(7 downto 0) := X"02";

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ctrl_gpio: std_logic_vector(2 downto 0);
	signal ctrl_rst_lock_mon, ctrl_cdr_edge, ctrl_sfp_edge, ctrl_hdmi_edge, ctrl_usfp_edge: std_logic;
	signal clk_i, clk_u, clk_cdr_i, clk_cdr_u, d_cdr_i, d_cdr_r, d_cdr_f, d_hdmi_i, d_hdmi_r, d_hdmi_f, d_usfp_i, d_usfp_r, d_usfp_f, q_i, q_hdmi_i, q_usfp_i: std_logic;
	signal mmcm_bad, mmcm_ok, pll_bad, pll_ok, mmcm_lm, pll_lm: std_logic;
	signal clkdiv: std_logic_vector(1 downto 0);
	signal sda_o, usfp_sda_o: std_logic;
	
  attribute IOB: string;
  attribute IOB of q_i, q_hdmi_i, q_usfp_i: signal is "TRUE";

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
      sel => ipbus_sel_pdts_pc059_io(ipb_in.ipb_addr),
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
		
	stat(0) <= X"000" & pll_lm & mmcm_lm & pll_ok & mmcm_ok & sfp_los & '0' & not clk_lolb & cdr_lol & cdr_los & ucdr_lol & ucdr_los & usfp_fault & usfp_los;
	
	soft_rst <= ctrl(0)(0);
	nuke <= ctrl(0)(1);
	rst <= ctrl(0)(2);
	rstb_clk <= not ctrl(0)(3);
	rstb_i2cmux <= not ctrl(0)(4);
	rstb_i2c <= not ctrl(0)(5);
	ctrl_rst_lock_mon <= ctrl(0)(6);
	inmux <= ctrl(0)(10 downto 8);
	ctrl_gpio <= ctrl(0)(14 downto 12);
	ledb <= not ctrl(0)(18 downto 16);
	ctrl_cdr_edge <= ctrl(0)(20);
	ctrl_sfp_edge <= ctrl(0)(21);
	ctrl_hdmi_edge <= ctrl(0)(22);
	ctrl_usfp_edge <= ctrl(0)(23);
	
	usfp_txdis <= '0';
	
-- Config info

	config: entity work.ipbus_roreg_v
		generic map(
			N_REG => 1,
			DATA(31 downto 24) => X"00",
			DATA(23 downto 16) => BOARD_TYPE,
			DATA(15 downto 8) => CARRIER_TYPE,
			DATA(7 downto 0) => DESIGN_TYPE
		)
		port map(
			ipb_in => ipbw(N_SLV_CONFIG),
			ipb_out => ipbr(N_SLV_CONFIG)
		);

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
			i => clk_cdr_p,
			ib => clk_cdr_n,
			o => clk_cdr_u
		);
		
	bufh_clk_cdr: BUFG
		port map(
			i => clk_cdr_u,
			o => clk_cdr_i
		);
		
	clk_cdr <= clk_cdr_i;
	
-- Clock lock monitor

	mmcm_bad <= not locked;
	pll_bad <= not clk_lolb;

	chk: entity work.pdts_chklock
		generic map(
			N => 2
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			los(0) => mmcm_bad,
			los(1) => pll_bad,
			ok(0) => mmcm_ok,
			ok(1) => pll_ok,
			ok_sticky(0) => mmcm_lm,
			ok_sticky(1) => pll_lm
		);

-- Data inputs

	ibufds_cdr: IBUFDS
		port map(
			i => d_cdr_p,
			ib => d_cdr_n,
			o => d_cdr_i
		);
		
	iddr_cdr: IDDR
		generic map(
			DDR_CLK_EDGE => "SAME_EDGE"
		)
		port map(
			q1 => d_cdr_r,
			q2 => d_cdr_f,
			c => clk_cdr_i,
			ce => '1',
			d => d_cdr_i,
			r => '0',
			s => '0'
		);
		
	d_cdr <= d_cdr_r when ctrl_cdr_edge = '0' else d_cdr_f;
	
	d_g: for i in 7 downto 0 generate
	
		signal di, dr, df: std_logic;
		
	begin
	
		ibufds_d: IBUFDS
			port map(
				i => d_p(i),
				ib => d_n(i),
				o => di
			);
			
		iddr_d: IDDR
			generic map(
				DDR_CLK_EDGE => "SAME_EDGE"
			)
			port map(
				q1 => dr,
				q2 => df,
				c => clk_i,
				ce => '1',
				d => di,
				r => '0',
				s => '0'
			);
 	
		d(i) <= dr when ctrl_sfp_edge = '0' else df;
		
	end generate;
		
	ibufds_hdmi: IBUFDS
		port map(
			i => d_hdmi_p,
			ib => d_hdmi_n,
			o => d_hdmi_i
		);
		
	iddr_hdmi: IDDR
		generic map(
			DDR_CLK_EDGE => "SAME_EDGE"
		)
		port map(
			q1 => d_hdmi_r,
			q2 => d_hdmi_f,
			c => clk_i,
			ce => '1',
			d => d_hdmi_i,
			r => '0',
			s => '0'
		);
		
	d_hdmi <= d_hdmi_r when ctrl_hdmi_edge = '0' else d_hdmi_f;
	
	ibufds_usfp: IBUFDS
		port map(
			i => d_usfp_p,
			ib => d_usfp_n,
			o => d_usfp_i
		);
		
	iddr_usfp: IDDR
		generic map(
			DDR_CLK_EDGE => "SAME_EDGE"
		)
		port map(
			q1 => d_usfp_r,
			q2 => d_usfp_f,
			c => clk_i,
			ce => '1',
			d => d_usfp_i,
			r => '0',
			s => '0'
		);
		
	d_usfp <= d_usfp_r when ctrl_usfp_edge = '0' else d_usfp_f;
	
-- Data outputs

	q_i <= q when falling_edge(clk_i);

	obuf_q: OBUFDS
		port map(
			i => q_i,
			o => q_p,
			ob => q_n
		);

	q_hdmi_i <= q_hdmi when falling_edge(clk_i);

	obuf_q_hdmi: OBUFDS
		port map(
			i => q_hdmi_i,
			o => q_hdmi_p,
			ob => q_hdmi_n
		);

	q_usfp_i <= q_usfp when falling_edge(clk_i);
	
	obuf_q_usfp: OBUFDS
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
